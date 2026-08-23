#!/usr/bin/env python3
"""Generates Ember/Resources/Localizable.xcstrings from structured definitions.

Source of truth for ALL user-facing copy (English + French).
Run from repo root:  python3 tools/gen_strings.py [--merge tools/content_strings.py]

Every entry: key -> (english, french). Plurals/format use %lld / %@.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Ember" / "Resources" / "Localizable.xcstrings"

S = {}

def k(key, en, fr):
    S[key] = (en, fr)

# ---------------------------------------------------------------------------
# Common controls
# ---------------------------------------------------------------------------
k("common.continue", "Continue", "Continuer")
k("common.back", "Back", "Retour")
k("common.done", "Done", "Terminé")
k("common.close", "Close", "Fermer")
k("common.delete", "Delete", "Supprimer")
k("common.keep", "Keep", "Conserver")
k("common.cancel", "Cancel", "Annuler")
k("common.ok", "OK", "OK")

# ---------------------------------------------------------------------------
# Welcome
# ---------------------------------------------------------------------------
k("welcome.tagline", "Something in you wants to feel closer.",
  "Quelque chose en vous veut se sentir plus proche.")
k("welcome.sub", "Start with what you want back.",
  "Commencez par ce que vous voulez retrouver.")
k("welcome.cta", "Begin", "Commencer")
k("welcome.note", "Private by design. Nothing you write leaves this device.",
  "Confidentiel par nature. Rien de ce que vous écrivez ne quitte cet appareil.")

# ---------------------------------------------------------------------------
# Age gate
# ---------------------------------------------------------------------------
k("agegate.title", "EMBER speaks about desire — with adults.",
  "EMBER parle de désir — avec des adultes.")
k("agegate.body",
  "This is a space for grown conversations about intimacy. Please confirm you are 18 or older.",
  "Cet espace accueille des conversations adultes sur l'intimité. Merci de confirmer que vous avez 18 ans ou plus.")
k("agegate.confirm", "I am 18 or older", "J'ai 18 ans ou plus")

# ---------------------------------------------------------------------------
# Journey selection
# ---------------------------------------------------------------------------
k("selection.title", "What do you want back?",
  "Que voulez-vous retrouver ?")
k("selection.subtitle",
  "Choose the pull you feel most. You can change course later.",
  "Choisissez ce qui vous attire le plus. Vous pourrez changer d'orientation plus tard.")
k("intention.myDesire.name", "My Desire", "Mon désir")
k("intention.myDesire.tagline", "I want to feel desire again.",
  "J'ai envie de retrouver le désir.")
k("intention.theirDesire.name", "Their Desire", "Leur désir")
k("intention.theirDesire.tagline", "I miss feeling wanted.",
  "Le fait de me sentir désiré·e me manque.")
k("intention.ourDesire.name", "Our Desire", "Notre désir")
k("intention.ourDesire.tagline", "We want our spark back.",
  "Nous voulons retrouver notre étincelle.")
k("selection.their.note",
  "Their Desire is about tending the conditions attraction grows in — never about persuading anyone.",
  "Leur désir, c'est cultiver ce qui permet à l'attraction de revenir — jamais convaincre qui que ce soit.")
k("selection.begin", "Continue", "Continuer")

# ---------------------------------------------------------------------------
# Onboarding questions
# ---------------------------------------------------------------------------
k("questions.heading", "A few gentle questions, so EMBER follows your situation — not an average.",
  "Quelques questions en douceur, pour que EMBER suive votre situation — pas une moyenne.")
k("questions.counter", "Question %lld of %lld", "Question %lld sur %lld")
k("questions.skipnote", "Answer with your gut — it knows more than you think.",
  "Répondez au ressenti — il en sait plus que vous ne croyez.")

# Shared
k("q.duration.text", "How long has it felt this way?",
  "Depuis combien de temps en êtes-vous là ?")
k("q.duration.weeks", "A few weeks", "Quelques semaines")
k("q.duration.months", "A few months", "Quelques mois")
k("q.duration.long", "A year or more", "Un an ou davantage")
k("q.duration.unsure", "Hard to say — it crept up", "Difficile à dire — c'est venu en douceur")

k("q.stress.text", "How much weight are you carrying lately?",
  "Quelle charge portez-vous ces derniers temps ?")
k("q.stress.light", "Not much — life feels manageable", "Pas trop — la vie reste gérable")
k("q.stress.some", "A steady hum of stress", "Un stress de fond, constant")
k("q.stress.heavy", "A lot, most days", "Beaucoup, presque chaque jour")
k("q.stress.swings", "It swings wildly", "Cela varie énormément")

# My Desire
k("q.my.state.text", "When you tune inward, desire right now feels…",
  "Quand vous vous écoutez, le désir, aujourd'hui, ressemble à…")
k("q.my.state.quiet", "Mostly quiet", "Plutôt silencieux")
k("q.my.state.flicker", "Like embers — there, then gone", "À des braises — là, puis parti")
k("q.my.state.blocked", "Present, but something's in the way",
  "Présent, mais quelque chose s'y oppose")
k("q.my.state.longing", "Longing without a shape", "Une envie floue, sans forme")

k("q.my.selfconnection.text", "When did you last feel at ease in your own body?",
  "Quand vous êtes-vous senti·e, pour la dernière fois, bien dans votre corps ?")
k("q.my.selfconnection.recent", "Recently", "Récemment")
k("q.my.selfconnection.passing", "Sometimes, in passing", "Parfois, fugitivement")
k("q.my.selfconnection.distant", "It's been a long time", "Cela fait longtemps")
k("q.my.selfconnection.unsure", "I rarely notice", "Je le remarque rarement")

k("q.my.pressure.text", "Wanting more can bring different feelings. Which is loudest?",
  "Vouloir davantage réveille différentes sensations. Laquelle parle le plus fort ?")
k("q.my.pressure.curiosity", "Curiosity", "La curiosité")
k("q.my.pressure.guilt", "A bit of guilt", "Une certaine culpabilité")
k("q.my.pressure.pressure", "Pressure", "La pression")
k("q.my.pressure.hope", "Quiet hope", "Un espoir discret")

# Their Desire
k("q.their.connection.text", "Between you two lately, the warmth feels…",
  "Entre vous deux, ces derniers temps, la chaleur semble…")
k("q.their.connection.warm", "Warm underneath the busyness",
  "Présente sous les occupations")
k("q.their.connection.faded", "Faded compared to before", "Plus discrète qu'avant")
k("q.their.connection.strained", "Strained", "Tendue")
k("q.their.connection.mixed", "Good days and far days", "Faite de bons jours et de jours lointains")

k("q.their.voice.text", "Saying what you miss out loud is…",
  "Dire à voix haute ce qui vous manque, c'est…")
k("q.their.voice.easy", "Something we can do", "Quelque chose qu'on sait faire")
k("q.their.voice.hard", "Possible, but hard", "Possible, mais difficile")
k("q.their.voice.avoided", "Mostly avoided", "Le plus souvent évité")
k("q.their.voice.oneWay", "I try; it doesn't land", "J'essaie, mais cela ne porte pas")

k("q.their.seen.text", "Being seen by them — how does it land these days?",
  "Se sentir vu·e par cette personne — qu'est-ce que ça donne, aujourd'hui ?")
k("q.their.seen.noted", "I still feel noticed", "Je me sens encore remarqué·e")
k("q.their.seen.fade", "It has faded", "Cela s'est estompé")
k("q.their.seen.invisible", "I feel invisible", "Je me sens invisible")
k("q.their.seen.loaded", "It feels loaded", "C'est devenu délicat")

# Our Desire
k("q.our.rhythm.text", "Your time together mostly runs on…",
  "Votre temps à deux tourne surtout au…")
k("q.our.rhythm.routine", "Loving routine", "Une routine tendre")
k("q.our.rhythm.logistics", "Logistics and tiredness", "Logistique et fatigue")
k("q.our.rhythm.parallel", "Parallel lives under one roof",
  "Deux vies parallèles sous un même toit")
k("q.our.rhythm.waves", "Waves of closeness and distance",
  "Vagues de proximité et de distance")

k("q.our.touch.text", "Touch between you — even small touches — usually feels…",
  "Vos contacts, même les plus légers, sont généralement…")
k("q.our.touch.alive", "Alive", "Vivants")
k("q.our.touch.rare", "Rare enough to notice", "Assez rares pour qu'on les remarque")
k("q.our.touch.functional", "Functional — hello, goodbye", "Fonctionnels — bonjour, au revoir")
k("q.our.touch.charged", "Complicated, almost charged", "Compliqués, presque électriques")

k("q.our.curiosity.text", "Curiosity about each other, these days, is…",
  "Votre curiosité l'un·e pour l'autre, aujourd'hui, est…")
k("q.our.curiosity.strong", "Still very much here", "Toujours bien vivante")
k("q.our.curiosity.dormant", "Dormant, but not gone", "Endormie, mais pas éteinte")
k("q.our.curiosity.buried", "Buried under to-do lists", "Enfouie sous les listes à faire")
k("q.our.curiosity.risky", "There, but it feels risky", "Là, mais elle semble risquée")

# ---------------------------------------------------------------------------
# Desire profile
# ---------------------------------------------------------------------------
k("profile.title", "Your Desire Profile", "Votre profil du désir")
k("profile.lede.myDesire",
  "Read this slowly. It describes your desire — no one else's.",
  "Lisez lentement. Il décrit votre désir — celui de personne d'autre.")
k("profile.lede.theirDesire",
  "This maps the ground attraction grows on — in you, and around you both.",
  "Ce portrait trace le terrain où l'attraction repousse — en vous comme entre vous.")
k("profile.lede.ourDesire",
  "Two people, one weather system. Here is the climate you described.",
  "Deux personnes, une même météo. Voici le climat que vous décrivez.")
k("profile.standout", "What stands out", "Ce qui ressort")

k("profile.dim.anticipation.opening",
  "Looking forward may matter more than the moment itself right now.",
  "En ce moment, l'attente compte peut-être plus que le moment lui-même.")
k("profile.dim.anticipation.middle",
  "Anticipation works on you when given room — a hint is often enough.",
  "L'anticipation vous touche quand on lui laisse de la place — un indice suffit souvent.")
k("profile.dim.anticipation.rich",
  "You answer strongly to anticipation; the approach matters as much as the arrival.",
  "Vous répondez fortement à l'anticipation : l'approche compte autant que l'arrivée.")

k("profile.dim.connection.opening",
  "When closeness runs thin, desire finds little to hold onto.",
  "Quand la proximité s'amincit, le désir trouve peu à quoi s'accrocher.")
k("profile.dim.connection.middle",
  "Emotional connection reliably warms things for you — conversation, in the truest sense, is intimacy.",
  "Le lien émotionnel vous échauffe sûrement — la conversation, au sens propre, fait partie de l'intimité.")
k("profile.dim.connection.rich",
  "Closeness is your engine: when you feel connected, desire follows easily.",
  "La proximité est votre moteur : quand vous vous sentez relié·e, le désir suit.")

k("profile.dim.novelty.opening",
  "Familiar comfort serves you better than novelty right now.",
  "Pour l'heure, le familier vous sert mieux que la nouveauté.")
k("profile.dim.novelty.middle",
  "A touch of newness reawakens attention — small departures beat grand gestures.",
  "Une pointe de nouveauté réveille l'attention — petits écarts valent mieux que grands gestes.")
k("profile.dim.novelty.rich",
  "Novelty wakes your desire quickly; sameness is what dims it.",
  "La nouveauté éveille vite votre désir ; c'est la répétition qui l'éteint.")

k("profile.dim.autonomy.opening",
  "Even gentle pressure may switch desire off — room to choose matters.",
  "Même une légère pression peut éteindre le désir — pouvoir choisir importe.")
k("profile.dim.autonomy.middle",
  "You open when nothing is expected of you; autonomy keeps the door unlocked.",
  "Vous vous ouvrez quand rien n'est attendu ; l'autonomie garde la porte entrouverte.")
k("profile.dim.autonomy.rich",
  "Freedom is essential to your desire: choice is what makes wanting possible.",
  "La liberté nourrit votre désir : choisir rend possible le fait de vouloir.")

k("profile.dim.selfConnection.opening",
  "Desire often starts as noticing yourself again — that attention may be due.",
  "Le désir commence souvent par se remarquer soi-même — cette attention vous attend.")
k("profile.dim.selfConnection.middle",
  "Small acts of self-attention restore the signal your desire listens for.",
  "De petites attentions à vous-même rétablissent le signal que votre désir écoute.")
k("profile.dim.selfConnection.rich",
  "You are in touch with yourself, and your desire speaks clearly because of it.",
  "Vous êtes à l'écoute de vous-même, et votre désir s'exprime clairement grâce à cela.")

k("profile.dim.confidence.opening",
  "Self-doubt may be standing between you and feeling wanted — gently.",
  "Le doute de soi se glisse parfois entre vous et le sentiment d'être désiré·e — doucement.")
k("profile.dim.confidence.middle",
  "For you, confidence grows from small evidence, not big leaps.",
  "Chez vous, la confiance naît de petites preuves, pas de grands sauts.")
k("profile.dim.confidence.rich",
  "You carry a quiet assurance your desire can build on.",
  "Vous portez une assurance tranquille sur laquelle votre désir peut s'appuyer.")

k("profile.dim.playfulness.opening",
  "Seriousness has been guarding something — play may be the way back in.",
  "Le sérieux veillait sur quelque chose — le jeu est peut-être le chemin du retour.")
k("profile.dim.playfulness.middle",
  "Playfulness lowers your guard faster than deep conversations do.",
  "Le jeu vous désarme plus vite que les grandes conversations.")
k("profile.dim.playfulness.rich",
  "Play is your native language of intimacy; laughter opens everything.",
  "Le jeu est votre langue maternelle intime ; le rire ouvre tout.")

k("profile.dim.communication.opening",
  "Unspoken things may be occupying the room where desire could live.",
  "Le non-dit occupe parfois la place où le désir pourrait vivre.")
k("profile.dim.communication.middle",
  "One honest exchange does more for you than a week of hints.",
  "Un seul échange sincère vous fait plus qu'une semaine de sous-entendus.")
k("profile.dim.communication.rich",
  "Words unlock you — honest talk is part of your intimacy.",
  "Les mots vous ouvrent — parler vrai fait partie de votre intimité.")

k("profile.dim.emotionalSafety.opening",
  "Safety first: your desire waits until tension has somewhere to go.",
  "La sécurité d'abord : votre désir attend que la tension trouve une issue.")
k("profile.dim.emotionalSafety.middle",
  "Predictable kindness settles you enough to want.",
  "Une gentillesse régulière vous apaise assez pour désirer.")
k("profile.dim.emotionalSafety.rich",
  "You have built real safety, and your desire trusts it.",
  "Vous avez bâti une vraie sécurité, et votre désir s'y fie.")

k("profile.footer",
  "Desire isn't a score. It's weather. This simply maps today's climate.",
  "Le désir n'est pas une note. C'est une météo. Ceci trace simplement le climat du jour.")
k("profile.cta", "Shape my journey", "Façonner mon parcours")

# ---------------------------------------------------------------------------
# Home
# ---------------------------------------------------------------------------
k("home.wordmark", "EMBER", "EMBER")
k("home.title", "Today", "Aujourd'hui")
k("home.day.label", "Day %lld of 21", "Jour %lld sur 21")
k("home.begin", "Begin Day %lld", "Commencer le jour %lld")
k("home.resume", "Continue Day %lld", "Reprendre au jour %lld")
k("home.complete.today", "Today is complete. Resting is part of the work.",
  "La journée est faite. Se reposer fait partie du travail.")
k("home.link.progress", "See the shape so far", "Voir le tracé parcouru")
k("home.link.settings", "Settings", "Réglages")
k("home.step.discover", "An idea", "Une idée")
k("home.step.reflect", "A question", "Une question")
k("home.step.act", "An experiment", "Une expérience")
k("home.step.return", "An evening check-in", "Un point du soir")

# ---------------------------------------------------------------------------
# Daily session
# ---------------------------------------------------------------------------
k("session.step.discover.title", "Discover", "Découvrir")
k("session.step.reflect.title", "Reflect", "Se poser la question")
k("session.step.act.title", "Experiment", "Expérimenter")
k("session.reflect.prompt", "If anything stirred, keep a line for yourself.",
  "Si quelque chose a remué, gardez-en une ligne pour vous.")
k("session.reflect.placeholder", "Written here, kept here.", "Écrit ici, gardé ici.")
k("session.reflect.save", "Keep privately", "Garder pour moi")
k("session.reflect.saved", "Kept on this device only.", "Conservé sur cet appareil uniquement.")
k("session.finish", "Done for today", "J'en fais mon affaire pour aujourd'hui")
k("session.finish.evening.teaser", "Come back this evening for a soft landing.",
  "Revenez ce soir pour un atterrissage en douceur.")

# ---------------------------------------------------------------------------
# Evening return
# ---------------------------------------------------------------------------
k("return.title", "How was it, honestly?", "Alors, honnêtement ?")
k("return.subtitle", "No wrong answers. Your evening shapes what comes next.",
  "Aucune mauvaise réponse. Votre soir dessine la suite.")
k("return.nothing", "Nothing changed", "Rien n'a changé")
k("return.noticed", "I noticed something", "J'ai remarqué quelque chose")
k("return.different", "It felt different", "C'était différent")
k("return.more", "I want more of this", "Je veux continuer sur cette lancée")
k("return.saved", "Saved. Tomorrow leans on this.", "Enregistré. Demain s'appuiera là-dessus.")
k("return.close.day", "Close the day", "Clôturer la journée")

# ---------------------------------------------------------------------------
# Progress
# ---------------------------------------------------------------------------
k("progress.title", "The Shape So Far", "Le tracé jusqu'ici")
k("progress.chapter.1", "Week one — Noticing", "Première semaine — Remarquer")
k("progress.chapter.2", "Week two — Kindling", "Deuxième semaine — Attiser")
k("progress.chapter.3", "Week three — Tending", "Troisième semaine — Entretenir")
k("progress.days", "%lld of 21 days traced", "%lld jours sur 21 tracés")
k("progress.empty", "Your first line appears after Day One.",
  "Votre premier trait apparaîtra après le premier jour.")
k("journal.title", "Your Words", "Vos mots")
k("journal.link", "Read your words", "Relire vos mots")
k("journal.day.label", "Day %lld", "Jour %lld")
k("journal.empty", "Nothing written yet. When a day stirs something, your words gather here — for you only.",
  "Rien pour l'instant. Quand un jour remue quelque chose, vos mots se rassemblent ici — pour vous seul.")

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
k("settings.title", "Settings", "Réglages")
k("settings.privacy.header", "Privacy, plainly", "La confidentialité, simplement")
k("settings.privacy.body",
  "Everything you write stays on this device, protected at rest.\nNothing is uploaded. There are no accounts, no analytics, no trackers.\nWhat you delete below is deleted for good.",
  "Tout ce que vous écrivez reste sur cet appareil, protégé au repos.\nRien n'est envoyé. Aucun compte, aucun traqueur, aucune publicité.\nCe que vous supprimez ci-dessous l'est définitivement.")
k("settings.data.header", "Your data", "Vos données")
k("settings.journey.header", "Your journey", "Votre parcours")
k("settings.reminder.header", "A gentle reminder", "Un rappel en douceur")
k("settings.reminder.toggle", "Remind me once a day", "Me rappeler une fois par jour")
k("settings.reminder.time", "At", "À")
k("settings.reminder.note",
  "Only on this device. A quiet nudge — no content, no streaks.",
  "Sur cet appareil uniquement. Une pensée discrète — sans contenu, sans séries.")
k("couple.handoff.placeholder",
  "Something to hand over, in your words…",
  "Quelque chose à transmettre, avec vos mots…")
k("reminder.title", "EMBER", "EMBER")
k("reminder.body",
  "A few quiet minutes are waiting, whenever you're ready.",
  "Quelques minutes tranquilles vous attendent, quand vous voulez.")
k("settings.data.delete", "Delete everything EMBER knows", "Tout supprimer")
k("settings.data.delete.confirm.title", "Delete all EMBER data?",
  "Supprimer toutes les données EMBER ?")
k("settings.data.delete.confirm.message",
  "Your answers, reflections and journey progress will be erased from this device immediately. This cannot be undone.",
  "Vos réponses, vos réflexions et votre progression seront effacées de cet appareil immédiatement. Cette action est irréversible.")
k("settings.data.delete.failed.title", "Deletion didn't complete",
  "La suppression n'a pas abouti")
k("settings.data.delete.failed.body",
  "Your data is untouched — nothing was erased. EMBER will not pretend otherwise. Try again in a moment; if this keeps happening, restart the app so it can reach your data safely.",
  "Vos données sont intactes — rien n'a été effacé. EMBER ne prétendra pas le contraire. Réessayez dans un instant ; si cela persiste, relancez l'app pour qu'elle puisse accéder à vos données en sécurité.")
k("settings.journey.restart", "Begin a different journey", "Commencer un autre parcours")
k("settings.journey.restart.confirm.message",
  "Your current journey progress and reflections will be erased so you can begin fresh.",
  "Votre parcours en cours et vos réflexions seront effacés pour repartir à neuf.")
k("settings.about.header", "About EMBER", "À propos d'EMBER")
k("settings.about.body",
  "EMBER is a private space for adults reconnecting with desire and closeness. It offers ideas and experiments — never diagnosis or therapy.",
  "EMBER est un espace privé pour les adultes qui renouent avec le désir et la proximité. Il propose des idées et des expériences — jamais un diagnostic ni une thérapie.")
k("settings.version", "Version %@", "Version %@")
k("settings.language.note", "EMBER speaks English and French.",
  "EMBER parle anglais et français.")

# ---------------------------------------------------------------------------
# Couple mode (Our Desire)
# ---------------------------------------------------------------------------
k("couple.setup.title", "One journey, two people", "Un parcours, deux personnes")
k("couple.setup.body",
  "Each of you receives a private space and daily steps of your own. What you write stays yours — sharing is always a deliberate hand-off, never automatic.",
  "Chacun reçoit un espace privé et ses propres étapes quotidiennes. Ce que vous écrivez vous appartient — partager est toujours un geste volontaire, jamais automatique.")
k("couple.consent",
  "We have both agreed to try this together — and either of us can stop anytime.",
  "Nous avons tous les deux accepté d'essayer ensemble — et chacun peut arrêter à tout moment.")
k("couple.role.question", "Who is holding the phone?", "Qui tient le téléphone ?")
k("couple.role.first", "Partner One", "Partenaire un")
k("couple.role.second", "Partner Two", "Partenaire deux")
k("couple.invite.header", "Claim your spaces", "Réclamez vos espaces")
k("couple.invite.body",
  "For now, EMBER pairs two people on one shared device. Set the code down between you — each space opens only when its owner chooses.",
  "Pour l'instant, EMBER associe deux personnes sur un appareil partagé. Posez le code entre vous — chaque espace ne s'ouvre que lorsque son propriétaire le décide.")
k("couple.switch.space", "Switch space", "Changer d'espace")
k("couple.space.private", "%@'s private space", "Espace privé — %@")
k("couple.shared.tonight", "Together tonight", "Ensemble ce soir")
k("couple.asymmetric.notice",
  "You each received your own step today. Compare notes only if you both choose to.",
  "Vous avez reçu chacun votre étape du jour. Ne comparez que si vous le décidez tous les deux.")
k("couple.privacy.rule",
  "Private reflections stay private. No view, export or reminder will ever surface a partner's words without their explicit hand-off.",
  "Les réflexions privées restent privées. Aucun écran, export ou rappel ne révèlera les mots d'un partenaire sans son geste explicite.")
k("couple.locked.other", "Locked. %@ keeps the key.", "Verrouillé. %@ garde la clé.")

# ---------------------------------------------------------------------------
# Accessibility extras
# ---------------------------------------------------------------------------
k("a11y.sketch.hero", "Hand-drawn sketch of two organic forms approaching each other",
  "Croquis dessiné à la main de deux formes organiques qui s'approchent")


def merge_extra(path: str):
    """Merge additional (key, en, fr) entries from an external module file."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("content_strings", path)
    if spec is None or spec.loader is None:
        raise SystemExit(f"cannot load {path}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    for key, (en, fr) in mod.S.items():
        S[key] = (en, fr)


def main():
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--merge":
            merge_extra(args[i + 1])
            i += 2
        else:
            raise SystemExit(f"unknown arg {args[i]}")

    catalog = {"sourceLanguage": "en", "version": "1.0", "strings": {}}
    for key, (en, fr) in sorted(S.items()):
        catalog["strings"][key] = {
            "localizations": {
                "en": {"stringUnit": {"state": "translated", "value": en}},
                "fr": {"stringUnit": {"state": "translated", "value": fr}},
            }
        }
    OUT.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {len(S)} strings -> {OUT}")


if __name__ == "__main__":
    main()
