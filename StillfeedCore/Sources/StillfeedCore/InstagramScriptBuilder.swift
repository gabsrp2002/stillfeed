import Foundation

public struct InstagramScriptBuilder: Sendable {
    public init() {}

    public func build(config: InstagramFilterConfig) -> ScriptBundle {
        let configJSON = ScriptComposer.encodeJSON(config)
        let upsellCSSSelectors = (AppUpsellScriptHelper.baseHiddenSelectors + [
            #"a[href^="instagram://"]"#,
            #"[role="dialog"]:has(a[href*="apps.apple.com"])"#,
            #"[role="dialog"]:has(a[href^="instagram://"])"#
        ]).joined(separator: ", ")
        let upsellJS = AppUpsellScriptHelper.buildHideBannersJS(
            appLinkSelector: #"a[href*="apps.apple.com"], a[href*="itunes.apple.com"], a[href^="instagram://"]"#,
            dialogSelector: #"[role="dialog"]"#,
            bannerSelector: #"div[style*="position: fixed"], div[style*="position:fixed"], header > div, section > div, aside"#,
            extraGuardSelector: #"a[href="/direct/inbox/"], a[href="/notifications/"], header"#
        )

        let startScript = """
        (function() {
          if (window.__stillfeedIgStartLoaded) return;
          window.__stillfeedIgStartLoaded = true;
          window.__stillfeedConfig = \(configJSON);

          var styleEl = document.createElement('style');
          styleEl.id = 'stillfeed-ig-style';
          (document.head || document.documentElement).appendChild(styleEl);

          function buildCSS(cfg) {
            var rules = [];

            // Hide "Open in App" / "Use the app" banners and App Store / native-scheme links
            rules.push('\(upsellCSSSelectors) { display: none !important; }');

            if (cfg.blockReelsFeedAndTab) {
              rules.push('a[href="/reels/"], a[href^="/reels/"], a[href*="/reels?"] { display: none !important; }');
              rules.push('html[data-stillfeed-page="reels"] main { opacity: 0 !important; pointer-events: none !important; }');
            }

            if (cfg.allowSingleReelFromDM) {
              rules.push('html[data-stillfeed-page="single-reel"] { overscroll-behavior: none !important; }');
              rules.push('html[data-stillfeed-page="single-reel"] main { scroll-snap-type: none !important; overflow-y: hidden !important; }');
            }

            if (cfg.hideStoriesTray) {
              rules.push('html[data-stillfeed-page="home"] [data-stillfeed-hidden="stories"] { display: none !important; }');
            }

            rules.push('[data-stillfeed-hidden="1"], [data-stillfeed-hidden="explore-grid"] { display: none !important; }');
            return rules.join('\\n');
          }

          window.__stillfeedRefreshCSS = function() {
            var cfg = window.__stillfeedConfig || {};
            styleEl.textContent = buildCSS(cfg);
          };

          window.__stillfeedRefreshCSS();
        })();
        """

        let endScript = """
        (function() {
          if (window.__stillfeedIgEndLoaded) return;
          window.__stillfeedIgEndLoaded = true;

          function updatePageAttribute() {
            var path = location.pathname || '/';
            var page = 'other';
            if (path === '/' || path === '') page = 'home';
            else if (path === '/reels' || path.indexOf('/reels/') === 0) page = 'reels';
            else if (path === '/reel' || path.indexOf('/reel/') === 0) page = 'single-reel';
            else if (path.indexOf('/explore') === 0) page = 'explore';
            else if (path.indexOf('/direct') === 0) page = 'direct';
            if (document.documentElement.getAttribute('data-stillfeed-page') !== page) {
              document.documentElement.setAttribute('data-stillfeed-page', page);
            }
            return page;
          }

          function enforceRouteRules() {
            var cfg = window.__stillfeedConfig || {};
            var path = location.pathname || '/';

            if (cfg.blockReelsFeedAndTab && (path === '/reels' || path.indexOf('/reels/') === 0)) {
              location.replace('https://www.instagram.com/?variant=following');
              return;
            }

            if (cfg.blockReelsFeedAndTab && !cfg.allowSingleReelFromDM && (path === '/reel' || path.indexOf('/reel/') === 0)) {
              location.replace('https://www.instagram.com/?variant=following');
              return;
            }

            if (cfg.preferFollowingFeed && (path === '/' || path === '')) {
              var params = new URLSearchParams(location.search || '');
              if (params.get('variant') !== 'following') {
                params.set('variant', 'following');
                location.replace('https://www.instagram.com/?' + params.toString());
              }
            }
          }

        \(upsellJS)

          function hideReelsNavAndLinks(cfg) {
            if (!cfg.blockReelsFeedAndTab) return;
            var links = document.querySelectorAll('a[href*="/reels"]');
            for (var i = 0; i < links.length; i++) {
              var container = links[i].closest('div[role="presentation"], li, nav > div > div') || links[i];
              markStillfeedHidden(container, '1');
            }
          }

          function handleExplorePage(cfg) {
            var path = location.pathname || '/';
            if (!cfg.blockExploreGridKeepSearch || path.indexOf('/explore') !== 0) return;

            var main = document.querySelector('main');
            if (!main) return;

            // Keep search input and username search results visible; hide the Explore media recommendation grid.
            var searchInput = main.querySelector('input[type="search"], input[placeholder*="Search"], input[aria-label*="Search"]');
            var isActivelySearching = searchInput && (searchInput.value || '').trim().length > 0;
            if (isActivelySearching) {
              var hiddenExplore = main.querySelectorAll('[data-stillfeed-hidden="explore-grid"]');
              for (var k = 0; k < hiddenExplore.length; k++) {
                hiddenExplore[k].removeAttribute('data-stillfeed-hidden');
              }
              return;
            }

            var mediaLinks = main.querySelectorAll('a[href^="/p/"], a[href^="/reel/"]');
            for (var i = 0; i < mediaLinks.length; i++) {
              var gridItem = mediaLinks[i].closest('div[style*="flex-direction"], article, div > div > div') || mediaLinks[i];
              if (searchInput && gridItem.contains(searchInput)) continue;
              markStillfeedHidden(gridItem, 'explore-grid');
            }
          }

          function stripSuggestedPosts(cfg) {
            if (!cfg.hideSuggestedAndSponsored) return;
            var path = location.pathname || '/';
            if (path !== '/' && path !== '') return;

            var suggestedPhrases = [
              'suggested for you',
              'suggested posts',
              'because you watched',
              'suggested reel',
              'sugestões para você',
              'sugerencias para ti'
            ];
            var followLabels = ['follow', 'seguir'];

            var articles = document.querySelectorAll('article');
            for (var i = 0; i < articles.length; i++) {
              var article = articles[i];
              if (article.getAttribute('data-stillfeed-hidden') === '1') continue;

              var rawText = (article.textContent || '').toLowerCase();
              var isSuggested = false;
              for (var p = 0; p < suggestedPhrases.length; p++) {
                if (rawText.indexOf(suggestedPhrases[p]) !== -1) {
                  isSuggested = true;
                  break;
                }
              }

              var spans = article.querySelectorAll('span, a');
              for (var j = 0; j < spans.length; j++) {
                var t = (spans[j].textContent || '').trim().toLowerCase();
                if (t === 'suggested for you' || t === 'sugestões para você' || t === 'sugerencias para ti') {
                  isSuggested = true;
                  break;
                }
              }

              // Posts from accounts you don't follow show a "Follow" / "Seguir" button in the post header.
              var hasFollowButton = false;
              var header = article.querySelector('header') || article;
              var actionBtns = header.querySelectorAll('button, div[role="button"]');
              for (var b = 0; b < actionBtns.length; b++) {
                var bt = (actionBtns[b].textContent || '').trim().toLowerCase();
                if (followLabels.indexOf(bt) !== -1) {
                  hasFollowButton = true;
                  break;
                }
              }

              if (isSuggested || hasFollowButton) {
                markStillfeedHidden(article, '1');
              }
            }
          }

          function handleStoriesTray(cfg) {
            if (!cfg.hideStoriesTray) return;
            if ((location.pathname || '/') !== '/') return;
            var lists = document.querySelectorAll('main ul, main div[role="menu"]');
            for (var i = 0; i < lists.length; i++) {
              var list = lists[i];
              if (list.querySelector('[aria-label*="Story"], [aria-label*="story"]')) {
                markStillfeedHidden(list.closest('div[role="region"]') || list, 'stories');
              }
            }
          }

          function clearPreviousHiddenFlags() {
            var hidden = document.querySelectorAll('[data-stillfeed-hidden]');
            for (var i = 0; i < hidden.length; i++) {
              hidden[i].removeAttribute('data-stillfeed-hidden');
            }
          }

          function sweep() {
            var cfg = window.__stillfeedConfig || {};
            updatePageAttribute();
            enforceRouteRules();
            hideAppUpsellBanners();
            hideReelsNavAndLinks(cfg);
            handleExplorePage(cfg);
            stripSuggestedPosts(cfg);
            handleStoriesTray(cfg);
          }

          // Prevent vertical swipe-to-next-reel when viewing a single DM-shared /reel/<id>.
          var touchStartY = null;
          window.addEventListener('touchstart', function(e) {
            if (e.touches && e.touches.length === 1) {
              touchStartY = e.touches[0].clientY;
            }
          }, { passive: true, capture: true });

          window.addEventListener('touchmove', function(e) {
            var cfg = window.__stillfeedConfig || {};
            var path = location.pathname || '/';
            if (!cfg.allowSingleReelFromDM || path.indexOf('/reel/') !== 0) return;
            if (touchStartY === null || !e.touches || e.touches.length !== 1) return;
            // Allow scrolling inside comment/share sheets or dialogs.
            if (e.target && e.target.closest && e.target.closest('[role="dialog"]')) return;
            var dy = Math.abs(e.touches[0].clientY - touchStartY);
            if (dy > 10) {
              e.preventDefault();
            }
          }, { passive: false, capture: true });

          window.addEventListener('wheel', function(e) {
            var cfg = window.__stillfeedConfig || {};
            var path = location.pathname || '/';
            if (!cfg.allowSingleReelFromDM || path.indexOf('/reel/') !== 0) return;
            if (e.target && e.target.closest && e.target.closest('[role="dialog"]')) return;
            if (Math.abs(e.deltaY) > 4) {
              e.preventDefault();
            }
          }, { passive: false, capture: true });

          function wrapHistoryMethod(methodName) {
            var original = history[methodName];
            history[methodName] = function() {
              var result = original.apply(this, arguments);
              setTimeout(sweep, 0);
              return result;
            };
          }

          wrapHistoryMethod('pushState');
          wrapHistoryMethod('replaceState');
          window.addEventListener('popstate', sweep);

          observeDOMWithThrottle(sweep, 80);

          window.__stillfeedUpdateConfig = function(nextConfig) {
            window.__stillfeedConfig = nextConfig;
            clearPreviousHiddenFlags();
            if (window.__stillfeedRefreshCSS) window.__stillfeedRefreshCSS();
            sweep();
          };

          sweep();
        })();
        """

        return ScriptBundle(documentStartScript: startScript, documentEndScript: endScript)
    }
}
