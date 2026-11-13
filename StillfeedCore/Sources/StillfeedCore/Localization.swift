import Foundation

/// Concrete UI translations supported by Stillfeed.
///
/// To onboard a new language:
/// 1. Add a case to `ConcreteLanguage` and `AppLanguage`.
/// 2. Provide its `AppCopy` value in `AppCopy.catalog(for:)`.
/// 3. Update `AppLanguage.resolve(preferredLanguages:)` prefix matching if needed.
public enum ConcreteLanguage: String, CaseIterable, Codable, Identifiable, Sendable {
    case english = "en"
    case portuguese = "pt"
    case spanish = "es"

    public var id: String { rawValue }

    public var nativeDisplayName: String {
        switch self {
        case .english: "English"
        case .portuguese: "Português"
        case .spanish: "Español"
        }
    }

    /// BCP-47 tag used in `hl` query parameters and JS `navigator.language`.
    public var webLocaleTag: String {
        switch self {
        case .english: "en"
        case .portuguese: "pt"
        case .spanish: "es"
        }
    }

    public var bcp47LanguageTag: String {
        switch self {
        case .english: "en-US"
        case .portuguese: "pt-BR"
        case .spanish: "es-ES"
        }
    }

    public var acceptLanguageHeader: String {
        switch self {
        case .english: "en-US,en;q=0.9"
        case .portuguese: "pt-BR,pt;q=0.9"
        case .spanish: "es-ES,es;q=0.9"
        }
    }
}

public enum AppLanguage: String, CaseIterable, Codable, Identifiable, Sendable {
    case system
    case english = "en"
    case portuguese = "pt"
    case spanish = "es"

    public var id: String { rawValue }

    public func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> ConcreteLanguage {
        switch self {
        case .system:
            for code in preferredLanguages {
                let lower = code.lowercased()
                if lower.hasPrefix("pt") { return .portuguese }
                if lower.hasPrefix("es") { return .spanish }
                if lower.hasPrefix("en") { return .english }
            }
            return .english
        case .english:
            return .english
        case .portuguese:
            return .portuguese
        case .spanish:
            return .spanish
        }
    }

    public func label(using copy: AppCopy) -> String {
        switch self {
        case .system: copy.languageSystemDefault
        case .english: ConcreteLanguage.english.nativeDisplayName
        case .portuguese: ConcreteLanguage.portuguese.nativeDisplayName
        case .spanish: ConcreteLanguage.spanish.nativeDisplayName
        }
    }
}

public struct AppCopy: Sendable {
    // Launcher
    public let launcherTagline: String
    public let protectionsActiveFormat: @Sendable (Int) -> String
    public let unlockedBadge: String
    public let filterSettingsAccessibility: String
    public let redirectOfficialAppsTitle: String
    public let redirectOfficialAppsSubtitle: String

    // Platform Browser
    public let backToHomeAccessibility: String
    public let quickDestinationsAccessibility: String
    public let reloadAccessibility: String

    // Quick Destinations
    public let igFollowingFeed: String
    public let igDirectMessages: String
    public let igSearch: String
    public let igProfile: String
    public let ytSubscriptions: String
    public let ytSearch: String
    public let ytLibrary: String

    // Summary badges
    public let summaryDMSafeReels: String
    public let summaryNoReels: String
    public let summaryNoExplore: String
    public let summaryCleanFeed: String
    public let summarySubscriptionsAndSearch: String
    public let summaryNoShorts: String
    public let summaryNoUpNext: String
    public let summaryFiltersPaused: String

    // Navigation Policy notices
    public let noticeBlockedReelsFeed: String
    public let noticeBlockedReel: String
    public let noticeBlockedShortsFeed: String
    public let noticeBlockedShort: String
    public let noticeOpenedShortInPlayer: String
    public let noticeWebProcessReloaded: String
    public let noticeWebProcessFailedRepeatedly: String
    public let noticeNavigationFailed: String

    // Settings
    public let settingsTitle: String
    public let doneButton: String
    public let cancelButton: String
    public let frictionActiveTitle: String
    public let frictionUnlockedTitle: String
    public let frictionHoldSubtitleFormat: @Sendable (Int) -> String
    public let frictionAutoLocksFormat: @Sendable (Int) -> String
    public let frictionAdjustFreely: String
    public let lockNowButton: String

    // Language Section
    public let languageSectionTitle: String
    public let appLanguageLabel: String
    public let languageSystemDefault: String
    public let applyLanguageToPlatformsLabel: String
    public let applyLanguageToPlatformsFooter: String

    // Instagram Section
    public let igSectionTitle: String
    public let igBlockReels: String
    public let igAllowSingleReelFromDM: String
    public let igBlockExploreKeepSearch: String
    public let igHideSuggestedPosts: String
    public let igForceFollowingOnly: String
    public let igHideStoriesTray: String

    // YouTube Section
    public let ytSectionTitle: String
    public let ytHideShorts: String
    public let ytOpenShortsInNormalPlayer: String
    public let ytReplaceHomeWithSubscriptions: String
    public let ytHideUpNext: String
    public let ytHideComments: String

    // Friction Settings Section
    public let frictionSettingsSectionTitle: String
    public let requireHoldToDisable: String
    public let holdDurationLabel: String
    public let secondsOptionFormat: @Sendable (Int) -> String
    public let autoRelockAfterLabel: String
    public let minutesOptionFormat: @Sendable (Int) -> String
    public let manualOnlyOption: String

    // Redirects & Sessions
    public let appRedirectsSectionTitle: String
    public let redirectOfficialAppsButton: String
    public let sessionsSectionTitle: String
    public let clearInstagramSession: String
    public let clearYouTubeSession: String
    public let clearSessionAlertTitleFormat: @Sendable (String) -> String
    public let clearSessionAlertAction: String
    public let clearSessionAlertMessage: String
    public let clearedSessionBannerFormat: @Sendable (String) -> String

    // Friction Challenge Sheet
    public let frictionChallengeNavTitle: String
    public let frictionChallengeTitle: String
    public let frictionChallengePromptFormat: @Sendable (Int) -> String
    public let holdButtonTitle: String
    public let keepHoldingSubtitle: String
    public let pressAndHoldSubtitle: String
    public let keepFiltersActiveButton: String

    // Shortcuts Setup Sheet
    public let shortcutsNavTitle: String
    public let shortcutsWhyTitle: String
    public let shortcutsWhyBody: String
    public let shortcutsStepsSectionTitle: String
    public let shortcutsStep1Title: String
    public let shortcutsStep1Detail: String
    public let shortcutsStep2Title: String
    public let shortcutsStep2Detail: String
    public let shortcutsStep3Title: String
    public let shortcutsStep3Detail: String
    public let deepLinksSectionTitle: String
    public let deepLinkAnyLabel: String
    public let copyButton: String
    public let copiedButton: String
    public let openShortcutsAutomationButton: String

    public static func forLanguage(
        _ language: AppLanguage,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> AppCopy {
        catalog(for: language.resolved(preferredLanguages: preferredLanguages))
    }

    public static func catalog(for language: ConcreteLanguage) -> AppCopy {
        switch language {
        case .english:
            return english
        case .portuguese:
            return portuguese
        case .spanish:
            return spanish
        }
    }
}

public extension AppCopy {
    static let english = AppCopy(
        launcherTagline: "Intentional social browsing with short-form video traps and algorithmic suggestions removed.",
        protectionsActiveFormat: { "\($0) protections active" },
        unlockedBadge: "• Unlocked",
        filterSettingsAccessibility: "Filter Settings",
        redirectOfficialAppsTitle: "Redirect Official Instagram & YouTube Apps",
        redirectOfficialAppsSubtitle: "Set up a 20-second iOS Shortcuts automation so tapping the normal apps opens Stillfeed instead.",
        backToHomeAccessibility: "Back to Stillfeed Home",
        quickDestinationsAccessibility: "Quick Destinations",
        reloadAccessibility: "Reload",
        igFollowingFeed: "Following Feed",
        igDirectMessages: "Direct Messages",
        igSearch: "Search",
        igProfile: "Profile",
        ytSubscriptions: "Subscriptions",
        ytSearch: "Search",
        ytLibrary: "Library",
        summaryDMSafeReels: "DM-Safe Reels",
        summaryNoReels: "No Reels",
        summaryNoExplore: "No Explore",
        summaryCleanFeed: "Clean Feed",
        summarySubscriptionsAndSearch: "Subscriptions & Search",
        summaryNoShorts: "No Shorts",
        summaryNoUpNext: "No Up Next",
        summaryFiltersPaused: "Filters Paused",
        noticeBlockedReelsFeed: "Blocked Reels feed",
        noticeBlockedReel: "Blocked Reel",
        noticeBlockedShortsFeed: "Blocked Shorts feed",
        noticeBlockedShort: "Blocked Short",
        noticeOpenedShortInPlayer: "Opened Short in standard player",
        noticeWebProcessReloaded: "Reloaded page after connection reset",
        noticeWebProcessFailedRepeatedly: "Page kept closing — tap Reload to try again",
        noticeNavigationFailed: "Couldn't load page — tap Reload to try again",
        settingsTitle: "Settings",
        doneButton: "Done",
        cancelButton: "Cancel",
        frictionActiveTitle: "Friction Lock Active",
        frictionUnlockedTitle: "Filters Temporarily Unlocked",
        frictionHoldSubtitleFormat: { "Turning protections off requires a \($0)s hold." },
        frictionAutoLocksFormat: { "Auto-locks in \($0) min" },
        frictionAdjustFreely: "You can adjust protections freely.",
        lockNowButton: "Lock Now",
        languageSectionTitle: "Language",
        appLanguageLabel: "App Language",
        languageSystemDefault: "System Default",
        applyLanguageToPlatformsLabel: "Apply to Instagram & YouTube",
        applyLanguageToPlatformsFooter: "Sends your selected language preference to Instagram and YouTube inside Stillfeed.",
        igSectionTitle: "Instagram",
        igBlockReels: "Block Reels Feed & Tab",
        igAllowSingleReelFromDM: "Allow Single Reel from DMs",
        igBlockExploreKeepSearch: "Block Explore Grid (Keep Search)",
        igHideSuggestedPosts: "Hide Suggested Posts",
        igForceFollowingOnly: "Force Following-Only Feed (Hides Stories)",
        igHideStoriesTray: "Hide Stories Tray",
        ytSectionTitle: "YouTube",
        ytHideShorts: "Hide Shorts Everywhere",
        ytOpenShortsInNormalPlayer: "Open /shorts/ in Normal Player",
        ytReplaceHomeWithSubscriptions: "Replace Home with Subscriptions",
        ytHideUpNext: "Hide \"Up Next\" Recommendations",
        ytHideComments: "Hide Video Comments",
        frictionSettingsSectionTitle: "Friction Lock Settings",
        requireHoldToDisable: "Require Hold to Disable Filters",
        holdDurationLabel: "Hold Duration",
        secondsOptionFormat: { "\($0) seconds" },
        autoRelockAfterLabel: "Auto Re-Lock After",
        minutesOptionFormat: { "\($0) minutes" },
        manualOnlyOption: "Manual only",
        appRedirectsSectionTitle: "App Redirects & Deep Links",
        redirectOfficialAppsButton: "Redirect Official Apps via Shortcuts",
        sessionsSectionTitle: "Sessions",
        clearInstagramSession: "Clear Instagram Session",
        clearYouTubeSession: "Clear YouTube Session",
        clearSessionAlertTitleFormat: { "Clear \($0) Session?" },
        clearSessionAlertAction: "Log Out & Clear Cookies",
        clearSessionAlertMessage: "You will need to sign in again the next time you open this platform.",
        clearedSessionBannerFormat: { "Cleared \($0) session." },
        frictionChallengeNavTitle: "Friction Lock",
        frictionChallengeTitle: "Take a Breath",
        frictionChallengePromptFormat: { "To weaken or disable filters, press and hold the button below continuously for \($0) seconds." },
        holdButtonTitle: "Hold",
        keepHoldingSubtitle: "Keep holding",
        pressAndHoldSubtitle: "Press & hold",
        keepFiltersActiveButton: "Keep Filters Active",
        shortcutsNavTitle: "Redirect Official Apps",
        shortcutsWhyTitle: "Why a 1-time Shortcuts setup?",
        shortcutsWhyBody: "Apple allows iCloud pop-ups only for regular Shortcuts—not Personal Automations that trigger when you open another app. Setting up a quick App Automation takes ~20 seconds and automatically bounces Instagram or YouTube into Stillfeed.",
        shortcutsStepsSectionTitle: "3-Step Automation Setup",
        shortcutsStep1Title: "Create an App Automation",
        shortcutsStep1Detail: "Tap \"Open Shortcuts Automation\" below, choose App, pick Instagram (or YouTube), select Is Opened, and choose Run Immediately.",
        shortcutsStep2Title: "Pick a Stillfeed Action",
        shortcutsStep2Detail: "Tap Next → New Blank Automation → search \"Stillfeed\" and choose \"Open Instagram in Stillfeed\" (or \"Open YouTube in Stillfeed\").",
        shortcutsStep3Title: "Or Use a Deep Link URL",
        shortcutsStep3Detail: "Alternatively, pick the \"Open URLs\" action in Shortcuts and paste one of the deep links below.",
        deepLinksSectionTitle: "Deep Links",
        deepLinkAnyLabel: "Any IG / YT Link",
        copyButton: "Copy",
        copiedButton: "Copied",
        openShortcutsAutomationButton: "Open Shortcuts Automation"
    )

    static let portuguese = AppCopy(
        launcherTagline: "Navegação intencional sem armadilhas de vídeos curtos nem sugestões algorítmicas.",
        protectionsActiveFormat: { "\($0) proteções ativas" },
        unlockedBadge: "• Desbloqueado",
        filterSettingsAccessibility: "Configurações de Filtros",
        redirectOfficialAppsTitle: "Redirecionar Apps Oficiais do Instagram e YouTube",
        redirectOfficialAppsSubtitle: "Configure uma automação de 20 segundos nos Atalhos do iOS para abrir o Stillfeed ao tocar nos apps normais.",
        backToHomeAccessibility: "Voltar para o início do Stillfeed",
        quickDestinationsAccessibility: "Atalhos rápidos",
        reloadAccessibility: "Recarregar",
        igFollowingFeed: "Feed Seguindo",
        igDirectMessages: "Mensagens Diretas",
        igSearch: "Buscar",
        igProfile: "Perfil",
        ytSubscriptions: "Inscrições",
        ytSearch: "Buscar",
        ytLibrary: "Biblioteca",
        summaryDMSafeReels: "Reels só por DM",
        summaryNoReels: "Sem Reels",
        summaryNoExplore: "Sem Explorar",
        summaryCleanFeed: "Feed Limpo",
        summarySubscriptionsAndSearch: "Inscrições e Busca",
        summaryNoShorts: "Sem Shorts",
        summaryNoUpNext: "Sem A Seguir",
        summaryFiltersPaused: "Filtros Pausados",
        noticeBlockedReelsFeed: "Feed de Reels bloqueado",
        noticeBlockedReel: "Reel bloqueado",
        noticeBlockedShortsFeed: "Feed de Shorts bloqueado",
        noticeBlockedShort: "Short bloqueado",
        noticeOpenedShortInPlayer: "Short aberto no player padrão",
        noticeWebProcessReloaded: "Página recarregada após reinício da conexão",
        noticeWebProcessFailedRepeatedly: "A página fechou repetidamente — toque em Recarregar",
        noticeNavigationFailed: "Não foi possível carregar — toque em Recarregar",
        settingsTitle: "Configurações",
        doneButton: "Concluir",
        cancelButton: "Cancelar",
        frictionActiveTitle: "Bloqueio de Fricção Ativo",
        frictionUnlockedTitle: "Filtros Temporariamente Desbloqueados",
        frictionHoldSubtitleFormat: { "Desativar proteções exige segurar o botão por \($0)s." },
        frictionAutoLocksFormat: { "Rebloqueia em \($0) min" },
        frictionAdjustFreely: "Você pode ajustar as proteções livremente.",
        lockNowButton: "Bloquear Agora",
        languageSectionTitle: "Idioma",
        appLanguageLabel: "Idioma do App",
        languageSystemDefault: "Padrão do Sistema",
        applyLanguageToPlatformsLabel: "Aplicar ao Instagram e YouTube",
        applyLanguageToPlatformsFooter: "Envia a preferência do idioma selecionado para o Instagram e o YouTube dentro do Stillfeed.",
        igSectionTitle: "Instagram",
        igBlockReels: "Bloquear Feed e Aba de Reels",
        igAllowSingleReelFromDM: "Permitir Reel único enviado por DM",
        igBlockExploreKeepSearch: "Bloquear Grade Explorar (Manter Busca)",
        igHideSuggestedPosts: "Ocultar Posts Sugeridos",
        igForceFollowingOnly: "Forçar Feed Seguindo (Oculta Stories)",
        igHideStoriesTray: "Ocultar Barra de Stories",
        ytSectionTitle: "YouTube",
        ytHideShorts: "Ocultar Shorts em Todo Lugar",
        ytOpenShortsInNormalPlayer: "Abrir /shorts/ no Player Normal",
        ytReplaceHomeWithSubscriptions: "Substituir Início por Inscrições",
        ytHideUpNext: "Ocultar Recomendações \"A seguir\"",
        ytHideComments: "Ocultar Comentários dos Vídeos",
        frictionSettingsSectionTitle: "Configurações do Bloqueio de Fricção",
        requireHoldToDisable: "Exigir Pressão Contínua para Desativar",
        holdDurationLabel: "Duração da Pressão",
        secondsOptionFormat: { "\($0) segundos" },
        autoRelockAfterLabel: "Rebloquear Automaticamente Após",
        minutesOptionFormat: { "\($0) minutos" },
        manualOnlyOption: "Somente manual",
        appRedirectsSectionTitle: "Redirecionamentos e Deep Links",
        redirectOfficialAppsButton: "Redirecionar Apps Oficiais via Atalhos",
        sessionsSectionTitle: "Sessões",
        clearInstagramSession: "Limpar Sessão do Instagram",
        clearYouTubeSession: "Limpar Sessão do YouTube",
        clearSessionAlertTitleFormat: { "Limpar sessão do \($0)?" },
        clearSessionAlertAction: "Sair e Limpar Cookies",
        clearSessionAlertMessage: "Você precisará fazer login novamente na próxima vez que abrir esta plataforma.",
        clearedSessionBannerFormat: { "Sessão do \($0) limpa." },
        frictionChallengeNavTitle: "Bloqueio de Fricção",
        frictionChallengeTitle: "Respire Fundo",
        frictionChallengePromptFormat: { "Para enfraquecer ou desativar filtros, pressione e segure o botão abaixo continuamente por \($0) segundos." },
        holdButtonTitle: "Segure",
        keepHoldingSubtitle: "Continue segurando",
        pressAndHoldSubtitle: "Pressione e segure",
        keepFiltersActiveButton: "Manter Filtros Ativos",
        shortcutsNavTitle: "Redirecionar Apps Oficiais",
        shortcutsWhyTitle: "Por que configurar uma vez nos Atalhos?",
        shortcutsWhyBody: "A Apple só permite pop-ups do iCloud para Atalhos comuns — não para Automações Pessoais acionadas ao abrir outro app. Configurar uma automação de App leva cerca de 20 segundos e redireciona o Instagram ou o YouTube direto para o Stillfeed.",
        shortcutsStepsSectionTitle: "Configuração em 3 Passos",
        shortcutsStep1Title: "Criar uma Automação de App",
        shortcutsStep1Detail: "Toque em \"Abrir Automação nos Atalhos\" abaixo, escolha App, selecione Instagram (ou YouTube), marque Ao Abrir e escolha Executar Imediatamente.",
        shortcutsStep2Title: "Escolher uma Ação do Stillfeed",
        shortcutsStep2Detail: "Toque em Seguinte → Nova Automação em Branco → busque \"Stillfeed\" e escolha \"Open Instagram in Stillfeed\" (ou \"Open YouTube in Stillfeed\").",
        shortcutsStep3Title: "Ou Usar uma URL de Deep Link",
        shortcutsStep3Detail: "Como alternativa, escolha a ação \"Abrir URLs\" nos Atalhos e cole um dos deep links abaixo.",
        deepLinksSectionTitle: "Deep Links",
        deepLinkAnyLabel: "Qualquer link do IG / YT",
        copyButton: "Copiar",
        copiedButton: "Copiado",
        openShortcutsAutomationButton: "Abrir Automação nos Atalhos"
    )

    static let spanish = AppCopy(
        launcherTagline: "Navegación intencional sin trampas de videos cortos ni sugerencias algorítmicas.",
        protectionsActiveFormat: { "\($0) protecciones activas" },
        unlockedBadge: "• Desbloqueado",
        filterSettingsAccessibility: "Ajustes de Filtros",
        redirectOfficialAppsTitle: "Redirigir Apps Oficiales de Instagram y YouTube",
        redirectOfficialAppsSubtitle: "Configura una automatización de 20 segundos en Atajos de iOS para abrir Stillfeed al tocar las apps normales.",
        backToHomeAccessibility: "Volver al inicio de Stillfeed",
        quickDestinationsAccessibility: "Accesos rápidos",
        reloadAccessibility: "Recargar",
        igFollowingFeed: "Feed Siguiendo",
        igDirectMessages: "Mensajes Directos",
        igSearch: "Buscar",
        igProfile: "Perfil",
        ytSubscriptions: "Suscripciones",
        ytSearch: "Buscar",
        ytLibrary: "Biblioteca",
        summaryDMSafeReels: "Reels solo por DM",
        summaryNoReels: "Sin Reels",
        summaryNoExplore: "Sin Explorar",
        summaryCleanFeed: "Feed Limpio",
        summarySubscriptionsAndSearch: "Suscripciones y Búsqueda",
        summaryNoShorts: "Sin Shorts",
        summaryNoUpNext: "Sin Siguiente",
        summaryFiltersPaused: "Filtros Pausados",
        noticeBlockedReelsFeed: "Feed de Reels bloqueado",
        noticeBlockedReel: "Reel bloqueado",
        noticeBlockedShortsFeed: "Feed de Shorts bloqueado",
        noticeBlockedShort: "Short bloqueado",
        noticeOpenedShortInPlayer: "Short abierto en el reproductor estándar",
        noticeWebProcessReloaded: "Página recargada tras reinicio de conexión",
        noticeWebProcessFailedRepeatedly: "La página se cerró repetidamente — toca Recargar",
        noticeNavigationFailed: "No se pudo cargar la página — toca Recargar",
        settingsTitle: "Ajustes",
        doneButton: "Listo",
        cancelButton: "Cancelar",
        frictionActiveTitle: "Bloqueo de Fricción Activo",
        frictionUnlockedTitle: "Filtros Desbloqueados Temporalmente",
        frictionHoldSubtitleFormat: { "Desactivar protecciones requiere mantener pulsado \($0)s." },
        frictionAutoLocksFormat: { "Se bloquea en \($0) min" },
        frictionAdjustFreely: "Puedes ajustar las protecciones libremente.",
        lockNowButton: "Bloquear Ahora",
        languageSectionTitle: "Idioma",
        appLanguageLabel: "Idioma de la App",
        languageSystemDefault: "Predeterminado del Sistema",
        applyLanguageToPlatformsLabel: "Aplicar a Instagram y YouTube",
        applyLanguageToPlatformsFooter: "Envía tu preferencia de idioma a Instagram y YouTube dentro de Stillfeed.",
        igSectionTitle: "Instagram",
        igBlockReels: "Bloquear Feed y Pestaña de Reels",
        igAllowSingleReelFromDM: "Permitir un Reel enviado por DM",
        igBlockExploreKeepSearch: "Bloquear Cuadrícula Explorar (Mantener Búsqueda)",
        igHideSuggestedPosts: "Ocultar Publicaciones Sugeridas",
        igForceFollowingOnly: "Forzar Feed Siguiendo (Oculta Historias)",
        igHideStoriesTray: "Ocultar Barra de Historias",
        ytSectionTitle: "YouTube",
        ytHideShorts: "Ocultar Shorts en Todas Partes",
        ytOpenShortsInNormalPlayer: "Abrir /shorts/ en Reproductor Normal",
        ytReplaceHomeWithSubscriptions: "Reemplazar Inicio por Suscripciones",
        ytHideUpNext: "Ocultar Recomendaciones \"A continuación\"",
        ytHideComments: "Ocultar Comentarios de Videos",
        frictionSettingsSectionTitle: "Ajustes del Bloqueo de Fricción",
        requireHoldToDisable: "Requerir Mantener Pulsado para Desactivar",
        holdDurationLabel: "Duración al Mantener",
        secondsOptionFormat: { "\($0) segundos" },
        autoRelockAfterLabel: "Volver a Bloquear Tras",
        minutesOptionFormat: { "\($0) minutos" },
        manualOnlyOption: "Solo manual",
        appRedirectsSectionTitle: "Redirecciones y Deep Links",
        redirectOfficialAppsButton: "Redirigir Apps Oficiales con Atajos",
        sessionsSectionTitle: "Sesiones",
        clearInstagramSession: "Borrar Sesión de Instagram",
        clearYouTubeSession: "Borrar Sesión de YouTube",
        clearSessionAlertTitleFormat: { "¿Borrar sesión de \($0)?" },
        clearSessionAlertAction: "Cerrar Sesión y Borrar Cookies",
        clearSessionAlertMessage: "Tendrás que iniciar sesión de nuevo la próxima vez que abras esta plataforma.",
        clearedSessionBannerFormat: { "Sesión de \($0) borrada." },
        frictionChallengeNavTitle: "Bloqueo de Fricción",
        frictionChallengeTitle: "Tómate un Respiro",
        frictionChallengePromptFormat: { "Para reducir o desactivar filtros, mantén pulsado el botón de abajo de forma continua durante \($0) segundos." },
        holdButtonTitle: "Mantén",
        keepHoldingSubtitle: "Sigue manteniendo",
        pressAndHoldSubtitle: "Mantén pulsado",
        keepFiltersActiveButton: "Mantener Filtros Activos",
        shortcutsNavTitle: "Redirigir Apps Oficiales",
        shortcutsWhyTitle: "¿Por qué configurar Atajos una vez?",
        shortcutsWhyBody: "Apple solo permite ventanas emergentes de iCloud para Atajos normales, no para Automatizaciones Personales al abrir otra app. Configurar una automatización de App toma unos 20 segundos y redirige Instagram o YouTube directamente a Stillfeed.",
        shortcutsStepsSectionTitle: "Configuración en 3 Pasos",
        shortcutsStep1Title: "Crear una Automatización de App",
        shortcutsStep1Detail: "Toca \"Abrir Automatización en Atajos\" abajo, elige App, selecciona Instagram (o YouTube), marca Al Abrirse y elige Ejecutar de Inmediato.",
        shortcutsStep2Title: "Elegir una Acción de Stillfeed",
        shortcutsStep2Detail: "Toca Siguiente → Nueva Automatización en Blanco → busca \"Stillfeed\" y elige \"Open Instagram in Stillfeed\" (o \"Open YouTube in Stillfeed\").",
        shortcutsStep3Title: "O Usar una URL de Deep Link",
        shortcutsStep3Detail: "Como alternativa, elige la acción \"Abrir URL\" en Atajos y pega uno de los deep links de abajo.",
        deepLinksSectionTitle: "Deep Links",
        deepLinkAnyLabel: "Cualquier enlace de IG / YT",
        copyButton: "Copiar",
        copiedButton: "Copiado",
        openShortcutsAutomationButton: "Abrir Automatización en Atajos"
    )
}
