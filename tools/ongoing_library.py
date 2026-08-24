# Mission 004: ongoing-library expansion. Adds variants 4-6 for every
# theme's discover/reflect/act pools and return variants 3-4, so the daily
# engine can honor its cooldowns indefinitely (8 themes x 6 units = 48
# discovers alone). EN+FR. Quality bar: no paraphrase spam; each unit is a
# distinct angle on its theme.

S = {}

def k(key, en, fr):
    S[key] = (en, fr)

# ------------------------------- DISCOVER 4-6 -------------------------------

k("theme.discover.attention.4",
  "Attention has a direction. Spend it on what is quietly improving — the plant that grew, the friend who texted first — and you train yourself to notice aliveness anywhere.",
  "L'attention a une direction. Portez-la sur ce qui s'améliore en silence — la plante qui a poussé, l'ami·e qui a écrit en premier — et vous vous apprenez à remarquer la vie partout.")
k("theme.discover.attention.5",
  "Numbness is not the absence of feeling; it is feeling, muffled. Under it there is usually one clear signal waiting — hunger, tiredness, longing. Attention is how you take the muff off.",
  "L'engourdissement n'est pas l'absence de ressenti ; c'est du ressenti étouffé. Dessous attend souvent un signal clair — faim, fatigue, manque. L'attention retire le moufle.")
k("theme.discover.attention.6",
  "You cannot fake attention and you cannot force it — but you can invite it. Slow down by ten percent today and watch what was invisible at full speed.",
  "On ne peut ni feindre l'attention ni la forcer — mais on peut l'inviter. Ralentissez de dix pour cent aujourd'hui et regardez ce qui était invisible à pleine vitesse.")

k("theme.discover.body.4",
  "Your body remembers pleasure your mind has filed away — a swim, a stretch, someone's hand. Visiting those memories somatically, not just mentally, reopens channels.",
  "Votre corps se souvient de plaisirs que votre tête a classés — une nage, un étirement, une main. Les revisiter dans le corps, pas seulement en pensée, rouvre des canaux.")
k("theme.discover.body.5",
  "Desire lives in the present tense of the body — temperature, weight, breath. Ten seconds of honest sensation can outweigh an hour of thinking about it.",
  "Le désir vit au présent du corps — température, poids, souffle. Dix secondes de sensation honnête peuvent dépasser une heure à y penser.")
k("theme.discover.body.6",
  "A body at war with itself cannot want. Today, call a truce: eat something good, move until warm, rest before exhausted. Truces precede appetites.",
  "Un corps en guerre contre lui-même ne peut désirer. Aujourd'hui, signez une trêve : mangez quelque chose de bon, bougez jusqu'à avoir chaud, reposez-vous avant l'épuisement. Les trêves précèdent les appétits.")

k("theme.discover.anticipation.4",
  "Anticipation rewards patience twice: once in the looking-forward, once in the arrival. Stretch the distance between wanting and having — the stretch itself is pleasurable.",
  "L'anticipation récompense deux fois la patience : dans l'attente, puis dans l'arrivée. Étirez la distance entre vouloir et avoir — l'étirement est déjà le plaisir.")
k("theme.discover.anticipation.5",
  "A date on the calendar changes the texture of ordinary days. One small planned thing this week colors everything before it.",
  "Une date au calendrier change la texture des jours ordinaires. Une seule petite chose prévue cette semaine colore tout ce qui la précède.")
k("theme.discover.anticipation.6",
  "Secrecy and anticipation are old friends. You don't need an audience for your plans — some look-forwards are warmer when kept between you and yourself.",
  "Le secret et l'anticipation sont de vieilles amies. Vos projets n'ont pas besoin de public — certaines attentes sont plus chaudes quand elles restent entre vous et vous.")

k("theme.discover.novelty.4",
  "Novelty doesn't require new places — only new eyes. The street you walk daily is different at 7am, in rain, backwards. Same map, new territory.",
  "La nouveauté n'exige pas de nouveaux lieux — seulement de nouveaux yeux. La rue que vous traversez chaque jour est autre à 7h, sous la pluie, à reculons. Même carte, territoire neuf.")
k("theme.discover.novelty.5",
  "Habit dulls precisely what repetition was meant to protect. Break one pattern gently — not to reject the familiar, but to see if it still fits.",
  "L'habitude émousse exactement ce que la répétition voulait protéger. Brisez doucement un schéma — non pour rejeter le familier, mais pour vérifier qu'il va toujours.")
k("theme.discover.novelty.6",
  "First times have a flavor. You cannot manufacture them often, but you can notice near-firsts: the first rain this month, the first time you laugh this hard this week.",
  "Les premières fois ont une saveur. Impossible d'en fabriquer souvent, mais les quasi-premières existent : première pluie du mois, premier fou rire pareil de la semaine.")

k("theme.discover.communication.4",
  "Asking is a form of generosity. A real question — asked to hear, not to answer — tells someone their inner world matters.",
  "Demander est une forme de générosité. Une vraie question — posée pour entendre, pas pour répondre — dit à quelqu'un que son monde intérieur compte.")
k("theme.discover.communication.5",
  "Some truths shrink when spoken and others grow. You find out which only after saying them — choose something small enough to risk.",
  "Certaines vérités rétrécissent quand on les dit, d'autres grandissent. On ne sait lequel qu'après — choisissez-en une assez petite pour oser.")
k("theme.discover.communication.6",
  "Silence has grammar. The pause before answering, the message left unread — these communicate too. Learning to read silence doubles your vocabulary.",
  "Le silence a sa grammaire. La pause avant de répondre, le message non lu — tout cela parle aussi. Lire le silence double votre vocabulaire.")

k("theme.discover.play.4",
  "Play is the opposite not of work but of purpose. An hour with no point — wandering, doodling, humming — returns you to yourself looser than you left.",
  "Le jeu n'est pas l'inverse du travail mais du but. Une heure sans raison — errer, gribouiller, fredonner — vous rend à vous-même plus souple qu'au départ.")
k("theme.discover.play.5",
  "Laughter syncs bodies faster than conversation. Something absurd, shared or alone — the belly kind, not the polite kind.",
  "Le rire synchronise les corps plus vite que la conversation. Quelque chose d'absurde, à deux ou seul·e — du ventre, pas poli.")
k("theme.discover.play.6",
  "Competence is overrated in play. Do something you are charmingly bad at — the point is the losing gracefully, not winning anything.",
  "La compétence est surestimée dans le jeu. Faites quelque chose où vous êtes charmamment mauvais·e — il s'agit de perdre avec grâce, pas de gagner.")

k("theme.discover.closeness.4",
  "Closeness is built from tiny proofs. Not declarations — evidence. The tea made unprompted, the detail remembered, the question followed up.",
  "La proximité se construit de petites preuves. Pas des déclarations — des indices. Le thé préparé sans qu'on demande, le détail retenu, la question reprise.")
k("theme.discover.closeness.5",
  "You can be close to someone across a table or across a year. Closeness is measured in understanding, not proximity — and understanding survives distance better than touch does.",
  "On peut être proche de quelqu'un à travers une table ou une année. La proximité se mesure à la compréhension, pas aux mètres — et elle survit mieux à la distance que le contact.")
k("theme.discover.closeness.6",
  "Letting yourself be needed — or asking for help — both weave connection. Independence is lovely; total self-sufficiency is a wall with good lighting.",
  "Se laisser aider comme demander de l'aide tissent le lien. L'autonomie est belle ; l'auto-suffisance totale est un mur bien éclairé.")

k("theme.discover.autonomy.4",
  "Wanting begins where obligation ends. Map one obligation you carry that nobody actually asked of you — and imagine setting it down.",
  "Le désir commence là où finit l'obligation. Repérez une obligation que personne ne vous a vraiment demandée — et imaginez la poser.")
k("theme.discover.autonomy.5",
  "Your yes means more when your no is available. Practice a small refusal today so your agreements stay honest.",
  "Votre oui vaut plus quand votre non reste disponible. Entraînez-vous à un petit refus aujourd'hui pour garder vos accords honnêtes.")
k("theme.discover.autonomy.6",
  "Nobody can want on a schedule. Protecting your own timing — for rest, for interest, for appetite — is not indulgence; it is infrastructure.",
  "Personne ne peut désirer sur commande. Protéger votre propre rythme — pour le repos, l'intérêt, l'appétit — n'est pas un caprice ; c'est de l'infrastructure.")

# ------------------------------- REFLECT 4-6 -------------------------------

k("theme.reflect.attention.4", "What improved slightly while you weren't watching?", "Qu'est-ce qui s'est légèrement amélioré pendant que vous regardiez ailleurs ?")
k("theme.reflect.attention.5", "If your numbness could speak, what would it be protecting?", "Si votre engourdissement savait parler, que protégerait-il ?")
k("theme.reflect.attention.6", "What did you almost miss today?", "Qu'avez-vous presque manqué aujourd'hui ?")

k("theme.reflect.body.4", "What does your body want that you keep postponing?", "Que demande votre corps que vous continuez à remettre à plus tard ?")
k("theme.reflect.body.5", "Where were you comfortable today — truly, physically comfortable?", "Où étiez-vous à l'aise aujourd'hui — vraiment, physiquement ?")
k("theme.reflect.body.6", "What memory lives in your hands?", "Quel souvenir habite vos mains ?")

k("theme.reflect.anticipation.4", "What are you willing to wait well for?", "Pour quoi vaut-il la peine d'attendre bien ?")
k("theme.reflect.anticipation.5", "Which day this week already holds something small to look forward to?", "Quel jour de cette semaine contient déjà une petite chose à attendre ?")
k("theme.reflect.anticipation.6", "What would you plan if nobody needed to know?", "Que projetteriez-vous si personne n'avait besoin de le savoir ?")

k("theme.reflect.novelty.4", "What did you notice differently this week?", "Qu'avez-vous remarqué différemment cette semaine ?")
k("theme.reflect.novelty.5", "Which habit is protecting you, and which is just hiding you?", "Quelle habitude vous protège, et laquelle vous cache ?")
k("theme.reflect.novelty.6", "When did something familiar last surprise you?", "Quand le familier vous a-t-il surpris pour la dernière fois ?")

k("theme.reflect.communication.4", "What question do you wish someone would ask you?", "Quelle question rêvez-vous qu'on vous pose ?")
k("theme.reflect.communication.5", "What did you say this week that cost you something?", "Qu'avez-vous dit cette semaine qui vous a coûté quelque chose ?")
k("theme.reflect.communication.6", "What has your silence been saying lately?", "Que dit votre silence ces derniers temps ?")

k("theme.reflect.play.4", "What did you enjoy before it had to be productive?", "Qu'aimiez-vous avant que ce soit censé être productif ?")
k("theme.reflect.play.5", "Who brings out your least serious self — and when did you last see them?", "Qui réveille votre moi le moins sérieux — et quand l'avez-vous vu ?")
k("theme.reflect.play.6", "What would you do tonight if embarrassment were free?", "Que feriez-vous ce soir si la gêne était gratuite ?")

k("theme.reflect.closeness.4", "Who knows the version of you that you like most?", "Qui connaît la version de vous que vous préférez ?")
k("theme.reflect.closeness.5", "What small proof of care reached you recently?", "Quelle petite preuve d'attention vous est parvenue récemment ?")
k("theme.reflect.closeness.6", "Where would a five-minute honesty change everything?", "Où cinq minutes d'honnêteté changeraient-elles tout ?")

k("theme.reflect.autonomy.4", "What did you agree to that you never actually chose?", "À quoi avez-vous consenti sans jamais vraiment choisir ?")
k("theme.reflect.autonomy.5", "When did you last change your mind freely?", "Quand avez-vous changé d'avis librement pour la dernière fois ?")
k("theme.reflect.autonomy.6", "What would you drop if permission weren't required?", "Que lâcheriez-vous si aucune permission n'était requise ?")

# ------------------------------- ACT 4-6 -------------------------------

k("theme.act.attention.4",
  "Text someone one specific thing you noticed about them lately — something only attention could have caught.",
  "Envoyez à quelqu'un un détail précis que vous avez remarqué sur lui récemment — quelque chose que seule l'attention pouvait saisir.")
k("theme.act.attention.5",
  "Eat one meal today without a screen. Just the food, its temperature, its taste.",
  "Prenez un repas aujourd'hui sans écran. Rien que la nourriture, sa température, son goût.")
k("theme.act.attention.6",
  "Step outside for three minutes and find one beautiful thing. That's all. One.",
  "Sortez trois minutes et trouvez une belle chose. C'est tout. Une.")

k("theme.act.body.4",
  "Warm water, slow hands: wash slowly tonight as if your body were telling you news.",
  "Eau chaude, gestes lents : lavez-vous doucement ce soir comme si votre corps vous racontait des nouvelles.")
k("theme.act.body.5",
  "Dance to one song — badly, closed doors optional. Let the body lead for three minutes.",
  "Dansez sur une chanson — mal, portes fermées ou non. Laissez le corps mener trois minutes.")
k("theme.act.body.6",
  "Go to bed one hour earlier than justified. Treat rest as desire's groundwork, not its failure.",
  "Couchez-vous une heure plus tôt que justifiable. Traitez le repos comme les fondations du désir, pas son échec.")

k("theme.act.anticipation.4",
  "Put one small pleasure on the calendar three days out. Visit the thought each morning until then.",
  "Inscrivez un petit plaisir au calendrier dans trois jours. Visitez cette pensée chaque matin d'ici là.")
k("theme.act.anticipation.5",
  "Describe tomorrow's best moment out loud tonight — give the waiting a voice.",
  "Décrivez à voix haute le meilleur moment de demain — donnez une voix à l'attente.")
k("theme.act.anticipation.6",
  "Choose Friday's small ritual today. The choosing counts double when it's early.",
  "Choisissez dès aujourd'hui le petit rituel de vendredi. Choisir tôt compte double.")

k("theme.act.novelty.4",
  "Take a different route home purely to see it. Notice three things you've never seen on the usual one.",
  "Rentrez par un autre chemin, rien que pour le voir. Remarquez trois choses invisibles sur le trajet habituel.")
k("theme.act.novelty.5",
  "Rearrange five objects where you live. Small chaos, fresh eyes.",
  "Déplacez cinq objets chez vous. Petit chaos, regard neuf.")
k("theme.act.novelty.6",
  "Try the food, song or show you've been curious about. Curiosity kept is curiosity dimmed.",
  "Essayez le plat, la chanson ou la série qui vous intriguent. La curiosité gardée s'éteint.")

k("theme.act.communication.4",
  "Ask someone a question today and don't fill the silences. Let their thinking breathe.",
  "Posez aujourd'hui une question et ne comblez pas les silences. Laissez leur réflexion respirer.")
k("theme.act.communication.5",
  "Write the message you've been drafting mentally. Send a shorter version.",
  "Écrivez le message que vous rédigez mentalement depuis des jours. Envoyez une version plus courte.")
k("theme.act.communication.6",
  "Say thank you once today with the reason included — not for the thing, for the noticing.",
  "Dites merci une fois aujourd'hui avec la raison incluse — pas pour la chose, mais pour l'attention.")

k("theme.act.play.4",
  "Invent a tiny ridiculous tradition and perform it once. It becomes a tradition by surviving.",
  "Inventez une minuscule tradition absurde et accomplissez-la une fois. Elle devient tradition en survivant.")
k("theme.act.play.5",
  "Take three photos today of things that are funny-shaped. Nothing useful. Just shapes.",
  "Photographiez trois choses aux formes drôles aujourd'hui. Rien d'utile. Des formes.")
k("theme.act.play.6",
  "Do one task in the strangest reasonable way possible — standing, singing, backwards. Absurdity is a door.",
  "Faites une tâche de la façon la plus étrange raisonnable — debout, en chantant, à l'envers. L'absurde est une porte.")

k("theme.act.closeness.4",
  "Ask someone how they really are and stay for the second answer — the real one.",
  "Demandez à quelqu'un comment il va vraiment et restez pour la seconde réponse — la vraie.")
k("theme.act.closeness.5",
  "Recreate one micro-tradition from early days: the same song, the same snack, the same bench.",
  "Recréez une micro-tradition des débuts : même chanson, même goûter, même banc.")
k("theme.act.closeness.6",
  "Ask for one small thing you'd normally handle alone. Receiving is also intimacy.",
  "Demandez une petite chose que vous géreriez normalement seul·e. Recevoir est aussi de l'intimité.")

k("theme.act.autonomy.4",
  "Block thirty minutes today that belong to no one. Defend them like a meeting with someone important.",
  "Bloquez trente minutes aujourd'hui qui n'appartiennent à personne. Défendez-les comme un rendez-vous important.")
k("theme.act.autonomy.5",
  "Wear, eat or do one thing purely because you want to — no justification prepared.",
  "Portez, mangez ou faites une chose uniquement par envie — sans justification prête.")
k("theme.act.autonomy.6",
  "Renegotiate one small commitment this week. Honest resizing beats silent resentment.",
  "Renégociez un petit engagement cette semaine. Redimensionner honnêteté bat ressentiment silencieux.")

# ------------------------------- RETURN 3-4 -------------------------------

k("theme.return.attention.3", "What deserved your attention more than it got today?", "Qu'est-ce qui méritait plus votre attention qu'elle n'en a reçu aujourd'hui ?")
k("theme.return.attention.4", "Did anything get warmer under your noticing?", "Quelque chose s'est-il réchauffé sous votre regard ?")
k("theme.return.body.3", "Where did your body feel most like yours today?", "Où votre corps s'est-il senti le plus vôtre aujourd'hui ?")
k("theme.return.body.4", "Did rest arrive — even briefly, even imperfectly?", "Le repos est-il venu — même brièvement, même imparfaitement ?")
k("theme.return.anticipation.3", "Is there a small thread of waiting you're enjoying?", "Y a-t-il un petit fil d'attente dont vous jouissez ?")
k("theme.return.anticipation.4", "Did planning something bring a flicker of appetite?", "Projeter quelque chose a-t-il fait passer un éclair d'envie ?")
k("theme.return.novelty.3", "What felt one degree different today?", "Qu'est-ce qui a semblé différent d'un degré aujourd'hui ?")
k("theme.return.novelty.4", "Did any routine loosen its grip, even slightly?", "Une routine a-t-elle un peu desserré son emprise ?")
k("theme.return.communication.3", "Did any words land the way you meant them?", "Des mots sont-ils arrivés comme vous les pensiez ?")
k("theme.return.communication.4", "Was there a silence today that said something true?", "Y a-t-il eu un silence aujourd'hui qui a dit quelque chose de vrai ?")
k("theme.return.play.3", "Did you catch yourself being ridiculous in a good way?", "Vous êtes-vous surpris·e à faire un ridicule réussi ?")
k("theme.return.play.4", "Was there room for lightness, or did the day refuse it?", "Y avait-il de la place pour la légèreté, ou la journée l'a-t-elle refusée ?")
k("theme.return.closeness.3", "Did you feel understood by anyone today — including yourself?", "Vous êtes-vous senti·e compris·e par quelqu'un aujourd'hui — y compris vous-même ?")
k("theme.return.closeness.4", "Was any warmth given, received, or remembered today?", "Une chaleur a-t-elle été donnée, reçue ou rappelée aujourd'hui ?")
k("theme.return.autonomy.3", "Did any choice today feel fully yours?", "Un choix aujourd'hui vous a-t-il entièrement appartenu ?")
k("theme.return.autonomy.4", "Did you protect any of your own time today?", "Avez-vous protégé un peu de votre temps aujourd'hui ?")

# ------------------- ONGOING HOME / ENGINE COPY (EN+FR) -------------------

k("home.today.label", "TODAY", "AUJOURD'HUI")
k("home.suggestion.line", "Here is what may be useful today.", "Voici ce qui pourrait vous servir aujourd'hui.")
