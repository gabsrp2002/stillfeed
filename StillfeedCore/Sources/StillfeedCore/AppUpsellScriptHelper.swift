import Foundation

/// Generates shared passive CSS selectors and DOM-sweeping JS to suppress mobile web
/// "Use the app" / "Open in app" banners, headers, and upsell modals across EN, PT, and ES.
enum AppUpsellScriptHelper {
    /// Exact normalized button/link labels that trigger app-upsell hiding.
    static let exactCTALabels: [String] = [
        // English
        "open app",
        "open in app",
        "open in the app",
        "open in instagram",
        "open in youtube",
        "use the app",
        "use app",
        "use the instagram app",
        "use instagram app",
        "use the youtube app",
        "use youtube app",
        "get the app",
        "get app",
        "get instagram",
        "get the instagram app",
        "get youtube",
        "get the youtube app",
        "get youtube app",
        "switch to the app",
        "switch to app",
        "continue in app",
        "continue in the app",
        "view in app",
        "view in the app",
        // Portuguese
        "usar o app",
        "usar app",
        "usar o aplicativo",
        "usar o app do instagram",
        "usar o app do youtube",
        "abrir no app",
        "abrir app",
        "abrir no aplicativo",
        "abrir no instagram",
        "abrir no youtube",
        "baixar o app",
        "baixar app",
        "obter o app",
        "obter app",
        "continuar no app",
        "ver no app",
        "ir para o app",
        // Spanish
        "usar la app",
        "usar la aplicación",
        "usar la app de instagram",
        "usar la app de youtube",
        "abrir en la app",
        "abrir en la aplicación",
        "abrir en instagram",
        "abrir en youtube",
        "descargar la app",
        "descargar app",
        "obtener la app",
        "obtener app",
        "continuar en la app",
        "ver en la app",
        "ir a la app"
    ]

    /// Multi-word phrases identifying compact fixed banners or modal dialogs prompting to use the native app.
    static let dialogPhrases: [String] = [
        "use the instagram app",
        "use the youtube app",
        "open in the instagram app",
        "open in the youtube app",
        "get the instagram app",
        "get the youtube app",
        "switch to the instagram app",
        "switch to the youtube app",
        "use the app",
        "open in app",
        "usar o app do instagram",
        "usar o app do youtube",
        "usar o aplicativo",
        "abrir no app",
        "usar la app de instagram",
        "usar la app de youtube",
        "usar la aplicación",
        "abrir en la app"
    ]

    /// Common native-app / App Store link selectors shared by both platforms.
    static let baseHiddenSelectors: [String] = [
        #"a[href*="apps.apple.com"]"#,
        #"a[href*="itunes.apple.com"]"#
    ]

    /// Builds JS that defines `hideAppUpsellBanners()` in the enclosing IIFE scope.
    static func buildHideBannersJS(
        appLinkSelector: String,
        dialogSelector: String,
        bannerSelector: String,
        extraGuardSelector: String
    ) -> String {
        let labelsJSON = ScriptComposer.encodeJSON(exactCTALabels)
        let phrasesJSON = ScriptComposer.encodeJSON(dialogPhrases)
        let appLinkJSON = ScriptComposer.encodeJSON(appLinkSelector)
        let dialogJSON = ScriptComposer.encodeJSON(dialogSelector)
        let bannerJSON = ScriptComposer.encodeJSON(bannerSelector)
        let guardJSON = ScriptComposer.encodeJSON(extraGuardSelector)

        return """
          var __stillfeedUpsellLabels = \(labelsJSON);
          var __stillfeedUpsellPhrases = \(phrasesJSON);
          var __stillfeedUpsellLabelSet = {};
          for (var __ui = 0; __ui < __stillfeedUpsellLabels.length; __ui++) {
            __stillfeedUpsellLabelSet[__stillfeedUpsellLabels[__ui]] = true;
          }

          function normalizeUpsellText(el) {
            return ((el && el.textContent) || '').replace(/\\s+/g, ' ').trim().toLowerCase();
          }

          function markStillfeedHidden(el, value) {
            if (!el) return;
            var targetValue = value || '1';
            if (el.getAttribute('data-stillfeed-hidden') !== targetValue) {
              el.setAttribute('data-stillfeed-hidden', targetValue);
            }
          }

          function observeDOMWithThrottle(runFn, delayMs) {
            var timer = null;
            var wait = typeof delayMs === 'number' ? delayMs : 80;
            function schedule() {
              if (timer !== null) return;
              timer = setTimeout(function() {
                timer = null;
                runFn();
              }, wait);
            }
            var observer = new MutationObserver(schedule);
            var target = document.body || document.documentElement;
            if (target) {
              observer.observe(target, { childList: true, subtree: true });
            }
            return observer;
          }

          function isProtectedUpsellContainer(node) {
            if (!node || node === document.body || node === document.documentElement) return true;
            if (node.id && node.id.indexOf('mount_') === 0) return true;
            var extraGuard = \(guardJSON);
            var guard = 'main, nav, article, form, input, textarea, select, video';
            if (extraGuard) guard += ', ' + extraGuard;
            if (node.matches && node.matches(guard)) return true;
            return !!(node.querySelector && node.querySelector(guard));
          }

          function resolveUpsellContainer(el) {
            var dialogSel = \(dialogJSON);
            var dlg = dialogSel && el.closest ? el.closest(dialogSel) : null;
            if (dlg && !isProtectedUpsellContainer(dlg) && normalizeUpsellText(dlg).length <= 400) {
              var parent = dlg.parentElement;
              if (parent && !isProtectedUpsellContainer(parent) && parent.children.length <= 2 && normalizeUpsellText(parent).length <= 400) {
                try {
                  if (window.getComputedStyle(parent).position === 'fixed') return parent;
                } catch (_) {}
              }
              return dlg;
            }

            var bannerSel = \(bannerJSON);
            var candidate = null;
            var cur = el.parentElement;
            for (var depth = 0; depth < 6 && cur; depth++) {
              if (isProtectedUpsellContainer(cur)) break;
              var txt = normalizeUpsellText(cur);
              if (txt.length > 220) break;
              // Do not hide a top navigation strip that holds more than banner actions.
              if (cur.querySelectorAll && cur.querySelectorAll('a, button').length > 3) break;
              var isFixedOrBanner = false;
              try {
                var pos = window.getComputedStyle(cur).position;
                if (pos === 'fixed' || pos === 'sticky') isFixedOrBanner = true;
              } catch (_) {}
              if (!isFixedOrBanner && bannerSel && cur.matches && cur.matches(bannerSel)) {
                isFixedOrBanner = true;
              }
              if (isFixedOrBanner) {
                candidate = cur;
              }
              cur = cur.parentElement;
            }
            return candidate || el;
          }

          function matchesUpsellLabel(el) {
            var text = normalizeUpsellText(el);
            if (text && __stillfeedUpsellLabelSet[text]) return true;
            var aria = ((el.getAttribute && el.getAttribute('aria-label')) || '').replace(/\\s+/g, ' ').trim().toLowerCase();
            return !!(aria && __stillfeedUpsellLabelSet[aria]);
          }

          function hideAppUpsellBanners() {
            var appLinkSel = \(appLinkJSON);
            var candidates = document.querySelectorAll(appLinkSel + ', a, button, [role="button"]');
            for (var i = 0; i < candidates.length; i++) {
              var el = candidates[i];
              if (el.closest && el.closest('[data-stillfeed-hidden]')) continue;
              var isAppLink = !!(el.matches && el.matches(appLinkSel));
              if (!isAppLink && !matchesUpsellLabel(el)) continue;
              var target = resolveUpsellContainer(el);
              if (target && !isProtectedUpsellContainer(target)) {
                markStillfeedHidden(target, '1');
              } else {
                markStillfeedHidden(el, '1');
              }
            }

            var dialogSel = \(dialogJSON);
            if (!dialogSel) return;
            var dialogs = document.querySelectorAll(dialogSel);
            for (var j = 0; j < dialogs.length; j++) {
              var dlg = dialogs[j];
              if (dlg.closest && dlg.closest('[data-stillfeed-hidden]')) continue;
              if (isProtectedUpsellContainer(dlg)) continue;
              var dlgText = normalizeUpsellText(dlg);
              if (!dlgText || dlgText.length > 400) continue;
              var matched = false;
              for (var p = 0; p < __stillfeedUpsellPhrases.length; p++) {
                if (dlgText.indexOf(__stillfeedUpsellPhrases[p]) !== -1) {
                  matched = true;
                  break;
                }
              }
              if (matched) {
                markStillfeedHidden(resolveUpsellContainer(dlg), '1');
              }
            }
          }
        """
    }
}
