import Foundation

public struct YouTubeScriptBuilder: Sendable {
    public init() {}

    public func build(config: YouTubeFilterConfig) -> ScriptBundle {
        let configJSON = ScriptComposer.encodeJSON(config)

        let startScript = """
        (function() {
          if (window.__stillfeedYtStartLoaded) return;
          window.__stillfeedYtStartLoaded = true;
          window.__stillfeedConfig = \(configJSON);

          var styleEl = document.createElement('style');
          styleEl.id = 'stillfeed-yt-style';
          (document.head || document.documentElement).appendChild(styleEl);

          function buildCSS(cfg) {
            var rules = [];

            // Hide "Open in YouTube" banners
            rules.push('ytm-mealbar-promo-renderer { display: none !important; }');

            if (cfg.hideShortsEverywhere) {
              rules.push('ytm-reel-shelf-renderer, ytm-shorts-lockup-view-model { display: none !important; }');
              rules.push('ytm-pivot-bar-item-renderer:has(div.pivot-shorts), ytm-pivot-bar-item-renderer[tab-identifier="FEshorts"] { display: none !important; }');
              rules.push('ytm-rich-section-renderer:has(ytm-reel-shelf-renderer), ytm-rich-section-renderer:has(ytm-shorts-lockup-view-model) { display: none !important; }');
              rules.push('ytm-video-with-context-renderer:has(a[href*="/shorts/"]), ytm-compact-video-renderer:has(a[href*="/shorts/"]), ytm-grid-video-renderer:has(a[href*="/shorts/"]) { display: none !important; }');
              rules.push('yt-tab-shape[tab-title="Shorts"], a[href$="/shorts"] { display: none !important; }');
            }

            if (cfg.replaceHomeWithSubscriptions) {
              rules.push('ytm-pivot-bar-item-renderer:has(div.pivot-w2w), ytm-pivot-bar-item-renderer[tab-identifier="FEwhat_to_watch"] { display: none !important; }');
            }

            if (cfg.hideUpNextRecommendations) {
              rules.push('ytm-watch-next-secondary-results-renderer, ytm-item-section-renderer[section-identifier="related-items"], #related { display: none !important; }');
              rules.push('.ytp-autonav-endscreen-countdown-container, ytm-autonav-bar { display: none !important; }');
            }

            if (cfg.hideComments) {
              rules.push('ytm-comments-entry-point-header-renderer, ytm-item-section-renderer[section-identifier="comment-item-section"], #comments { display: none !important; }');
            }

            rules.push('[data-stillfeed-hidden="1"] { display: none !important; }');
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
          if (window.__stillfeedYtEndLoaded) return;
          window.__stillfeedYtEndLoaded = true;

          function watchURLForShortsPath(pathname, search) {
            var rest = pathname.slice('/shorts/'.length);
            var id = rest.split('/')[0];
            if (!id) return null;
            var params = new URLSearchParams(search || '');
            params.set('v', id);
            params.delete('feature');
            return 'https://m.youtube.com/watch?' + params.toString();
          }

          function enforceRouteRules() {
            var cfg = window.__stillfeedConfig || {};
            var path = location.pathname || '/';

            if (path.indexOf('/shorts/') === 0) {
              if (cfg.redirectShortsToWatchPlayer) {
                var target = watchURLForShortsPath(path, location.search);
                if (target) {
                  location.replace(target);
                  return;
                }
              } else if (cfg.hideShortsEverywhere) {
                location.replace('https://m.youtube.com/feed/subscriptions');
                return;
              }
            }

            if ((cfg.hideShortsEverywhere || cfg.redirectShortsToWatchPlayer) && (path === '/shorts' || path === '/feed/shorts')) {
              location.replace('https://m.youtube.com/feed/subscriptions');
              return;
            }

            if (cfg.replaceHomeWithSubscriptions && (path === '/' || path === '')) {
              var params = new URLSearchParams(location.search || '');
              if (!params.has('v') && !params.has('search_query') && !params.has('list')) {
                location.replace('https://m.youtube.com/feed/subscriptions');
              }
            }
          }

          function sweepShortsAndUpNext() {
            var cfg = window.__stillfeedConfig || {};

            if (cfg.hideShortsEverywhere) {
              var shortLinks = document.querySelectorAll('a[href*="/shorts/"]');
              for (var i = 0; i < shortLinks.length; i++) {
                var card = shortLinks[i].closest('ytm-reel-shelf-renderer, ytm-shorts-lockup-view-model, ytm-video-with-context-renderer, ytm-compact-video-renderer, ytm-grid-video-renderer, ytm-rich-item-renderer');
                if (card) {
                  card.setAttribute('data-stillfeed-hidden', '1');
                }
              }
            }

            if (cfg.hideShortsEverywhere || cfg.replaceHomeWithSubscriptions) {
              var pivotItems = document.querySelectorAll('ytm-pivot-bar-item-renderer');
              for (var j = 0; j < pivotItems.length; j++) {
                var label = (pivotItems[j].textContent || '').trim().toLowerCase();
                if (cfg.hideShortsEverywhere && label === 'shorts') {
                  pivotItems[j].setAttribute('data-stillfeed-hidden', '1');
                }
                if (cfg.replaceHomeWithSubscriptions && label === 'home') {
                  pivotItems[j].setAttribute('data-stillfeed-hidden', '1');
                }
              }
            }

            if (cfg.hideUpNextRecommendations && (location.pathname || '').indexOf('/watch') === 0) {
              var sections = document.querySelectorAll('ytm-item-section-renderer');
              for (var k = 0; k < sections.length; k++) {
                var sec = sections[k];
                var idAttr = sec.getAttribute('section-identifier') || '';
                if (idAttr === 'related-items') {
                  sec.setAttribute('data-stillfeed-hidden', '1');
                }
              }
            }
          }

          function sweep() {
            enforceRouteRules();
            sweepShortsAndUpNext();
          }

          // Intercept clicks on /shorts/<id> links before YouTube's SPA router handles them.
          document.addEventListener('click', function(e) {
            var cfg = window.__stillfeedConfig || {};
            if (!cfg.redirectShortsToWatchPlayer) return;
            var anchor = e.target && e.target.closest ? e.target.closest('a[href*="/shorts/"]') : null;
            if (!anchor) return;
            try {
              var parsed = new URL(anchor.href, location.origin);
              if (parsed.pathname.indexOf('/shorts/') === 0) {
                var watchURL = watchURLForShortsPath(parsed.pathname, parsed.search);
                if (watchURL) {
                  e.preventDefault();
                  e.stopPropagation();
                  location.assign(watchURL);
                }
              }
            } catch (_) {}
          }, true);

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
          window.addEventListener('yt-navigate-start', sweep);
          window.addEventListener('yt-navigate-finish', sweep);

          var observer = new MutationObserver(function() {
            sweepShortsAndUpNext();
          });
          if (document.body) {
            observer.observe(document.body, { childList: true, subtree: true });
          }

          window.__stillfeedUpdateConfig = function(nextConfig) {
            window.__stillfeedConfig = nextConfig;
            var hidden = document.querySelectorAll('[data-stillfeed-hidden]');
            for (var i = 0; i < hidden.length; i++) {
              hidden[i].removeAttribute('data-stillfeed-hidden');
            }
            if (window.__stillfeedRefreshCSS) window.__stillfeedRefreshCSS();
            sweep();
          };

          sweep();
        })();
        """

        return ScriptBundle(documentStartScript: startScript, documentEndScript: endScript)
    }
}
