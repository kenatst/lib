# Theme-pool content: reflect/act/return variants per DayTheme, EN+FR.
# Merged into Localizable.xcstrings by gen_strings.py --merge tools/content_strings.py
#
# The content model: base discover copy stays day-keyed (editorial ideas read
# as a written arc), while reflect / act / return are THEMED pools. A day's
# theme decides which pool to draw from; the journey shape and a per-intention
# offset decide which variant — so the same day number offers genuinely
# different practices across the three journeys, and re-ordered days stay
# coherent automatically.

S = {}

def k(key, en, fr):
    S[key] = (en, fr)

# ---------------------------------------------------------------------------
# REFLECT pools — "theme.reflect.<n>" n=1..3
# ---------------------------------------------------------------------------

k("theme.reflect.attention.1",
  "What did you notice today that you usually walk straight past?",
  "Qu'avez-vous remarqué aujourd'hui d'habitude traversé sans un regard ?")
k("theme.reflect.attention.2",
  "Where did your attention rest today, even for a breath — and what kept it there?",
  "Où votre attention s'est-elle posée aujourd'hui, ne serait-ce qu'un souffle — et qu'est-ce qui l'a retenue ?")
k("theme.reflect.attention.3",
  "If your attention had a place of its own today, where would it have been sitting?",
  "Si votre attention avait un lieu à elle aujourd'hui, où se serait-elle assise ?")

k("theme.reflect.body.1",
  "Where in your body is there ease right now? Even a small patch counts.",
  "Où, dans votre corps, y a-t-il de l'aise en ce moment ? Même une petite zone compte.")
k("theme.reflect.body.2",
  "What did your body ask for today — and did you hear it before evening?",
  "De quoi votre corps a-t-il eu besoin aujourd'hui — et l'avez-vous entendu avant le soir ?")
k("theme.reflect.body.3",
  "Which sensation today felt most like you?",
  "Quelle sensation d'aujourd'hui vous a semblé la plus fidèle à vous-même ?")

k("theme.reflect.anticipation.1",
  "What are you quietly looking forward to right now? Let it be specific.",
  "Qu'attendez-vous avec une impatience discrète, en ce moment ? Précisez.")
k("theme.reflect.anticipation.2",
  "When was the last time the waiting itself felt good?",
  "La dernière fois que l'attente elle-même vous a fait du bien, c'était quand ?")
k("theme.reflect.anticipation.3",
  "What could you promise tomorrow — softly, with no deadline attached?",
  "Que pourriez-vous promettre à demain — doucement, sans échéance ?")

k("theme.reflect.novelty.1",
  "What was the smallest new thing in your day? Did it change anything after it?",
  "Quelle a été la plus petite chose nouvelle de votre journée ? A-t-elle changé ce qui a suivi ?")
k("theme.reflect.novelty.2",
  "What familiar thing did you manage to see as if for the first time?",
  "Quelle chose familière avez-vous réussi à voir comme pour la première fois ?")
k("theme.reflect.novelty.3",
  "What would \"new\" look like this week at a dose that doesn't scare you?",
  "À quoi ressemblerait « du nouveau » cette semaine, à une dose qui ne vous effraie pas ?")

k("theme.reflect.communication.1",
  "If one sentence could carry how you feel lately, what would it say?",
  "Si une phrase pouvait porter ce que vous ressentez ces temps-ci, laquelle serait-ce ?")
k("theme.reflect.communication.2",
  "What do you wish someone would ask you? Ask yourself first.",
  "Que souhaiteriez-vous qu'on vous demande ? Posez-vous d'abord la question vous-même.")
k("theme.reflect.communication.3",
  "What have you been saying with silence lately?",
  "Qu'avez-vous dit récemment par votre silence ?")

k("theme.reflect.play.1",
  "When did you last laugh at something no one else saw?",
  "Quand avez-vous ri pour la dernière fois de quelque chose que personne d'autre n'a vu ?")
k("theme.reflect.play.2",
  "What would play look like for you now — not as it was when you were ten?",
  "À quoi ressemblerait le jeu pour vous maintenant — pas comme à dix ans ?")
k("theme.reflect.play.3",
  "What's the most unserious thing you secretly enjoy? Defend it in one line.",
  "Quelle est la chose la moins sérieuse dont vous jouissez en secret ? Défendez-la en une ligne.")

k("theme.reflect.closeness.1",
  "Who did you feel closest to today — including future-you or memory?",
  "De qui vous êtes-vous senti·e le plus proche aujourd'hui — y compris vous futur·e ou un souvenir ?")
k("theme.reflect.closeness.2",
  "What small warmth reached you this week that nobody planned?",
  "Quelle petite chaleur est arrivée jusqu'à vous cette semaine sans que personne l'ait prévue ?")
k("theme.reflect.closeness.3",
  "Is this a season of closeness or distance for you? Name it without judging it.",
  "Êtes-vous dans une saison de proximité ou de distance ? Nommez-la sans la juger.")

k("theme.reflect.autonomy.1",
  "Where did you choose freely today — even in something tiny?",
  "Où avez-vous choisi librement aujourd'hui — même dans une broutille ?")
k("theme.reflect.autonomy.2",
  "What expectation on you feels heaviest right now? Whose voice is it in?",
  "Quelle attente pèse le plus sur vous en ce moment ? À quelle voix appartient-elle ?")
k("theme.reflect.autonomy.3",
  "If nothing were expected of you tonight, what would you reach for first?",
  "Si l'on n'attendait rien de vous ce soir, vers quoi iriez-vous d'abord ?")

# ---------------------------------------------------------------------------
# ACT pools — "theme.act.<n>" n=1..3
# ---------------------------------------------------------------------------

k("theme.act.attention.1",
  "Once today, follow your attention on purpose — watch light move, listen to one full song, look slowly at one face.",
  "Une fois aujourd'hui, suivez votre attention exprès — regardez la lumière bouger, écoutez une chanson entière, contemplez lentement un visage.")
k("theme.act.attention.2",
  "Pick one routine moment — the kettle, the key in the lock — and give it your full attention, as if rehearsing it for memory.",
  "Choisissez un moment routinier — la bouilloire, la clé dans la serrure — et portez-lui toute votre attention, comme pour le graver.")
k("theme.act.attention.3",
  "Sit for two unhurried minutes with the lights low and simply notice what you feel. Nothing to fix.",
  "Asseyez-vous deux minutes sans presser, lumière basse, et remarquez simplement ce que vous ressentez. Rien à réparer.")

k("theme.act.body.1",
  "Take a slower shower or bath than usual. Treat your own skin as terrain worth revisiting.",
  "Prenez une douche ou un bain plus lent que d'habitude. Considérez votre peau comme un territoire qui mérite qu'on y retourne.")
k("theme.act.body.2",
  "Stretch for three minutes tonight — not to improve anything, just to be informed by your own body.",
  "Étirez-vous trois minutes ce soir — non pour progresser, mais pour laisser votre corps vous renseigner.")
k("theme.act.body.3",
  "Wear or touch one fabric today purely for how it feels. Let comfort be the whole point.",
  "Portez ou touchez un tissu aujourd'hui rien que pour sa sensation. Que le confort soit tout le propos.")

k("theme.act.anticipation.1",
  "Plant one seed of anticipation: mention, lightly, that you have something small in mind for later this week.",
  "Plantez une graine d'anticipation : évoquez légèrement que vous avez quelque chose en tête pour plus tard cette semaine.")
k("theme.act.anticipation.2",
  "Whisper-plan tomorrow's smallest pleasure — the coffee, the light, ten quiet minutes. Then protect it.",
  "Ourdissez en sourdine le plus petit plaisir de demain — le café, la lumière, dix minutes calmes. Puis protégez-le.")
k("theme.act.anticipation.3",
  "Send a single line to someone safe about looking forward to something real. Nothing more needed.",
  "Envoyez une seule ligne, à quelqu'un de sûr, au sujet d'une attente bien réelle. Rien de plus.")

k("theme.act.novelty.1",
  "Change one detail of your usual: a different route, cup, playlist, or lamp. Notice how attention follows.",
  "Changez un détail de votre habitude : un autre trajet, tasse, playlist ou lampe. Remarquez comme l'attention suit.")
k("theme.act.novelty.2",
  "Choose one familiar object and give it five slow minutes. Let it become new.",
  "Choisissez un objet familier et offrez-lui cinq minutes lentes. Laissez-le redevient neuf.")
k("theme.act.novelty.3",
  "Do one small thing differently tonight — brush hair in a new order, sit elsewhere, reverse the ritual.",
  "Faites une petite chose différemment ce soir — coiffez-vous dans un autre ordre, asseyez-vous ailleurs, inversez le rituel.")

k("theme.act.communication.1",
  "Write one honest sentence about what you miss — and keep it where only you will find it.",
  "Écrivez une phrase honnête sur ce qui vous manque — et gardez-la où vous seul·e la trouverez.")
k("theme.act.communication.2",
  "Say aloud — to them, or just to yourself — one true thing about this week. No editing for effect.",
  "Dites à voix haute — à eux, ou à vous seul·e — une chose vraie à propos de cette semaine. Sans mise en scène.")
k("theme.act.communication.3",
  "Ask someone (or answer, in writing) one question you've never dared: what do you miss most?",
  "Posez à quelqu'un (ou répondez par écrit) une question jamais osée : qu'est-ce qui te manque le plus ?")

k("theme.act.play.1",
  "Do one deliberately playful thing today: an absurd comment, a silly walk past a mirror, a game you win alone.",
  "Faites une chose résolument joueuse aujourd'hui : un commentaire absurde, une démarche ridicule devant le miroir, une partie gagnée seul·e.")
k("theme.act.play.2",
  "Let someone catch you mid-delight today — humming, dancing, absorbed. Don't apologize for it.",
  "Laissez quelqu'un vous surprendre en plein ravissement — fredonnant, dansant, absorbé·e. Ne vous excusez pas.")
k("theme.act.play.3",
  "Make one ordinary task absurdly enjoyable tonight — music too loud, race against the timer, dessert first.",
  "Rendez une tâche ordinaire absurment agréable ce soir — musique trop forte, course contre le minuteur, dessert d'abord.")

k("theme.act.closeness.1",
  "Leave one small warmth for someone — or for future-you: a note, a folded shirt, a favorite mug set out.",
  "Laissez une petite chaleur à quelqu'un — ou au vous futur : un mot, une chemise pliée, la tasse préférée posée.")
k("theme.act.closeness.2",
  "Give three no-agenda touches today: a hand on a shoulder, a brush of arms — yours or theirs.",
  "Offrez trois contacts sans attente aujourd'hui : une main sur une épaule, un bras effleuré — le vôtre ou le leur.")
k("theme.act.closeness.3",
  "Recall one ritual from early days — same song, same seat. Recreate it tonight; let memory charge it.",
  "Retrouvez un rituel des premiers jours — même chanson, même siège. Recréez-le ce soir ; laissez la mémoire le charger.")

k("theme.act.autonomy.1",
  "Cancel or shorten one obligation today. Feel the room it leaves behind.",
  "Annulez ou raccourcissez une obligation aujourd'hui. Sentez la place qu'elle laisse derrière elle.")
k("theme.act.autonomy.2",
  "Tonight, remove all expectations from one hour. Whatever happens — or doesn't — is the point.",
  "Ce soir, retirez toute attente d'une heure entière. Ce qui arrive — ou non — est le propos.")
k("theme.act.autonomy.3",
  "Say one clear no today — small, kind, complete. Notice what space survives it.",
  "Dites un non clair aujourd'hui — petit, aimable, définitif. Remarquez l'espace qui lui survit.")

# ---------------------------------------------------------------------------
# RETURN pools — "theme.return.<n>" n=1..2 (evening check-in question)
# ---------------------------------------------------------------------------

k("theme.return.attention.1", "Did anything warm up under your attention today?", "Quelque chose s'est-il réchauffé sous votre attention aujourd'hui ?")
k("theme.return.attention.2", "Where did noticing take you today?", "Où la remarque vous a-t-elle mené·e aujourd'hui ?")
k("theme.return.body.1", "Did your body tell you anything today?", "Votre corps vous a-t-il dit quelque chose aujourd'hui ?")
k("theme.return.body.2", "Did ease show up anywhere in your body today?", "De l'aise est-elle apparue quelque part dans votre corps aujourd'hui ?")
k("theme.return.anticipation.1", "Is there anything you're quietly looking forward to now?", "Y a-t-il quelque chose que vous attendez déjà, discrètement ?")
k("theme.return.anticipation.2", "Did the waiting itself feel different today?", "L'attente elle-même vous a-t-elle paru différente aujourd'hui ?")
k("theme.return.novelty.1", "Did the familiar look even slightly new?", "Le familier vous a-t-il semblé un peu neuf ?")
k("theme.return.novelty.2", "Did one changed detail change anything after it?", "Un détail changé a-t-il modifié ce qui suivait ?")
k("theme.return.communication.1", "Was it hard to keep your words honest today? That's information too.", "A-t-il été difficile de garder vos mots honnêtes aujourd'hui ? C'est aussi une information.")
k("theme.return.communication.2", "Did saying (or writing) one true thing cost less than expected?", "Dire (ou écrire) une chose vraie a-t-il coûté moins cher que prévu ?")
k("theme.return.play.1", "Did anything make you smile at yourself today?", "Quelque chose vous a-t-il fait sourire de vous aujourd'hui ?")
k("theme.return.play.2", "Was there room today for something unserious?", "Y a-t-il eu de la place aujourd'hui pour quelque chose de peu sérieux ?")
k("theme.return.closeness.1", "Did any warmth land — given, received, or remembered?", "Une chaleur est-elle arrivée à bon port — donnée, reçue ou souvenir ?")
k("theme.return.closeness.2", "Can you name which season you're in yet?", "Arrivez-vous à nommer votre saison ?")
k("theme.return.autonomy.1", "Did choosing freely leave any trace today?", "Un choix libre vous a-t-il laissé une trace aujourd'hui ?")
k("theme.return.autonomy.2", "Did saying no (to something small) leave any room behind?", "Votre non (à quelque chose de petit) a-t-il laissé de l'espace derrière lui ?")
