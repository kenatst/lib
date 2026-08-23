# Theme pools for TITLES and DISCOVER essays (EN+FR), completing the
# theme-driven content model. A day's title, discover idea, reflect prompt,
# act experiment and evening question all come from its THEME pool — so any
# journey sequence stays coherent, and the three intentions genuinely differ.

S = {}

def k(key, en, fr):
    S[key] = (en, fr)

# --- ATTENTION -----------------------------------------------------------
k("theme.title.attention.1", "Noticing", "Remarquer")
k("theme.title.attention.2", "Soft Attention", "L'attention douce")
k("theme.title.attention.3", "Being Seen", "Être vu·e")
k("theme.discover.attention.1",
  "Desire often begins as attention. Before wanting anything more, notice what you already feel when the house goes quiet — warmth, numbness, curiosity, nothing. Whatever is there is information, not a verdict.",
  "Le désir commence souvent par l'attention. Avant d'en demander davantage, remarquez ce que vous ressentez déjà quand la maison se tait — chaleur, engourdissement, curiosité, rien. Tout ce qui est là est une information, pas un verdict.")
k("theme.discover.attention.2",
  "Attention is not a given; it is a practice. What you look at softly tends to warm. What you audit coldly tends to hide.",
  "L'attention n'est pas acquise ; c'est une pratique. Ce que vous regardez doucement tend à se réchauffer. Ce que vous auditez froidement tend à se cacher.")
k("theme.discover.attention.3",
  "Being wanted begins with being seen. Let yourself be witnessed in something small and true today — mid-hum, mid-absorption, unguarded — and notice that you survived it. That is the whole lesson.",
  "Se sentir désiré commence par être vu. Laissez-vous surprendre dans quelque chose de petit et vrai aujourd'hui — en train de fredonner, absorbé·e, sans garde — et remarquez que vous y avez survécu. C'est toute la leçon.")

# --- BODY ----------------------------------------------------------------
k("theme.title.body.1", "The Body's Schedule", "Le calendrier du corps")
k("theme.title.body.2", "Permission to Rest", "La permission de me reposer")
k("theme.title.body.3", "Terrain Worth Returning To", "Un territoire où revenir")
k("theme.discover.body.1",
  "The body keeps its own schedule, and it is not a timetable of obligation. Ease — not effort — is usually the door desire walks through. A body that feels watched performs; a body that feels safe can want.",
  "Le corps suit son propre calendrier, et ce n'est pas un emploi du temps d'obligations. L'aise — pas l'effort — est généralement la porte par laquelle le désir entre. Un corps qui se sent observé joue la comédie ; un corps en sécurité peut désirer.")
k("theme.discover.body.2",
  "Rest is part of desire. Tired bodies defend themselves with numbness — it is protection, not brokenness. Treat the numbness not as a fault to fix but as a gatekeeper to negotiate with gently.",
  "Le repos fait partie du désir. Les corps fatigués se défendent par l'engourdissement — c'est une protection, pas une casse. Traitez cet engourdissement non comme un défaut à réparer mais comme un gardien avec qui négocier doucement.")
k("theme.discover.body.3",
  "Curiosity about your own responses is the most durable kind. You are allowed to be a mystery to yourself. The question you cannot answer yet is worth keeping company with — answers rush; curiosity strolls.",
  "La curiosité envers vos propres réactions est la plus durable. Vous avez le droit d'être un mystère pour vous-même. La question à laquelle vous ne pouvez pas encore répondre mérite qu'on lui tienne compagnie — les réponses courent ; la curiosité se promène.")

# --- ANTICIPATION ----------------------------------------------------------
k("theme.title.anticipation.1", "The Sense of Before", "Le sens de l'avant")
k("theme.title.anticipation.2", "Ritual and Charge", "Rituel et tension")
k("theme.title.anticipation.3", "Carrying a Lit Match", "Porter une allumette allumée")
k("theme.discover.anticipation.1",
  "Anticipation is a sense in its own right. A hint today — a look held a moment longer, a message that promises nothing and implies everything — can do the quiet work of an entire evening.",
  "L'anticipation est un sens à part entière. Un indice aujourd'hui — un regard retenu une seconde de plus, un message qui ne promet rien et suggère tout — accomplit tranquillement le travail d'une soirée entière.")
k("theme.discover.anticipation.2",
  "Rituals hold tension beautifully. The same candle, the same song, the same seat on the sofa — repetition is not the enemy of desire; it is its memory. What was charged once can be charged again by signal alone.",
  "Les rituels tiennent bien la tension. La même bougie, la même chanson, la même place sur le canapé — la répétition n'est pas l'ennemie du désir ; elle en est la mémoire. Ce qui a été chargé une fois peut l'être de nouveau par le seul signal.")
k("theme.discover.anticipation.3",
  "Looking forward and arriving are different pleasures. Give the first one room today and the second one softens. Carry one small plan into tomorrow like a lit match cupped from wind.",
  "Attendre et arriver sont deux plaisirs différents. Donnez aujourd'hui de la place au premier et le second s'adoucit. Portez un petit projet vers demain comme une allumette protégée du vent.")

# --- NOVELTY ---------------------------------------------------------------
k("theme.title.novelty.1", "Right-Sized Newness", "Nouveauté à la bonne dose")
k("theme.title.novelty.2", "Looking Again", "Regarder encore")
k("theme.title.novelty.3", "A Doorway, Not a Leap", "Une porte, pas un saut")
k("theme.discover.novelty.1",
  "Novelty right-sized is a doorway, not a leap. One new lamp, one new playlist, one hour rearranged — attention follows difference like a cat follows movement. Grand gestures startle; small ones beckon.",
  "La nouveauté à la bonne dose est une porte, pas un saut. Une lampe différente, une playlist différente, une heure réagencée — l'attention suit la différence comme un chat suit le mouvement. Les grands gestes effarouchent ; les petits invitent.")
k("theme.discover.novelty.2",
  "Familiarity hides things in plain sight. The face you know by heart still changes daily. Looking again — slowly, as if for the first time — can make the known feel newly made.",
  "La familiarité cache des choses sous nos yeux. Le visage que vous connaissez par cœur change chaque jour. Regarder encore — lentement, comme pour la première fois — peut rendre le connu tout neuf.")
k("theme.discover.novelty.3",
  "Difference does not require drama. Rearranging a room, an order, an hour counts. What matters is that your attention wakes up and reports back.",
  "La différence n'exige pas le drame. Réarranger une pièce, un ordre, une heure suffit. L'essentiel est que votre attention se réveille et fasse son rapport.")

# --- COMMUNICATION -----------------------------------------------------------
k("theme.title.communication.1", "Drawing the Map", "Dessiner la carte")
k("theme.title.communication.2", "What I Miss", "Ce qui me manque")
k("theme.title.communication.3", "One True Sentence", "Une phrase vraie")
k("theme.discover.communication.1",
  "Words draw maps. When you can say what you miss — precisely, without blame — the territory between you and what you want becomes navigable. Vague longing stays lost; named longing finds roads.",
  "Les mots dessinent des cartes. Quand vous pouvez dire ce qui vous manque — précisément, sans reproche — le territoire entre vous et ce que vous voulez devient praticable. L'envie vague reste perdue ; l'envie nommée trouve des routes.")
k("theme.discover.communication.2",
  "\"I miss being looked at\" and \"I miss being taken\" are different countries. Naming which country you live in changes everything you might pack — for you, and for whoever travels with you.",
  "« On me regarde moins » et « je me sens désirable » sont deux pays différents. Savoir dans quel pays vous vivez change tout ce que vous pourriez emporter — pour vous, et pour celui ou celle qui voyage avec vous.")
k("theme.discover.communication.3",
  "Honesty is a skill, not a confession. One true sentence, spoken without editing for effect, weighs more than a perfectly managed conversation. Today, aim for true rather than impressive.",
  "L'honnêteté est une compétence, pas un aveu. Une phrase vraie, dite sans mise en scène, pèse plus qu'une conversation parfaitement gérée. Aujourd'hui, visez vrai plutôt qu'impressionnant.")

# --- PLAY -------------------------------------------------------------------
k("theme.title.play.1", "Seriousness, Off Duty", "Le sérieux en congé")
k("theme.title.play.2", "Caught Delighting", "Surpris·e en plein ravissement")
k("theme.title.play.3", "Absurdly Good Ideas", "Idées absurdes et bonnes")
k("theme.discover.play.1",
  "Play is seriousness with its shoes off. It is not childish — it is the oldest form of intimacy: two creatures signaling safety through laughter. Curiosity counts even when it ends only in giggles.",
  "Le jeu, c'est le sérieux qui a quitté ses chaussures. Ce n'est pas puéril — c'est la plus ancienne forme d'intimité : deux créatures qui annoncent la sécurité par le rire. La curiosité compte même quand elle finit en fou rire.")
k("theme.discover.play.2",
  "There is a specific charge in being caught delighting. Not performing pleasure — being absorbed by it. Witnessed joy is disarming precisely because it cannot be faked.",
  "Il y a une charge particulière à être surpris en plein ravissement. Non pas jouer le plaisir — être absorbé par lui. La joie témoignée désarme précisément parce qu'elle ne peut pas se simuler.")
k("theme.discover.play.3",
  "Play lowers the stakes so wanting can breathe. An absurd comment, a ridiculous dance, dessert before dinner — levity is not avoidance when everyone knows the game they are in.",
  "Le jeu abaisse les enjeux pour que l'envie respire. Un commentaire absurde, une danse ridicule, le dessert avant le dîner — la légèreté n'est pas de l'évitement quand chacun connaît le jeu auquel il participe.")

# --- CLOSENESS ----------------------------------------------------------------
k("theme.title.closeness.1", "Small Warmths", "Petites chaleurs")
k("theme.title.closeness.2", "Touch Without Agenda", "Le contact sans programme")
k("theme.title.closeness.3", "Seasons, Not Verdicts", "Des saisons, pas des verdicts")
k("theme.discover.closeness.1",
  "Closeness compounds quietly. One small warmth today — a folded shirt, a favorite mug set out, a hand on a shoulder passing by — outweighs a grand gesture saved for someday.",
  "La proximité compose en silence. Une petite chaleur aujourd'hui — une chemise pliée, une tasse préférée posée, une main sur une épaule au passage — pèse plus qu'un grand geste gardé pour un jour jamais venu.")
k("theme.discover.closeness.2",
  "Affection without agenda rebuilds trust in touch itself. A hand that wants nothing teaches the skin a new language. Give three no-agenda touches today and receive at least one without returning it like a debt.",
  "L'affection sans programme reconstruit la confiance dans le contact. Une main qui ne veut rien apprend une langue nouvelle à la peau. Offrez trois contacts sans attente aujourd'hui et recevez-en un sans le rendre comme une dette.")
k("theme.discover.closeness.3",
  "Distance and closeness take turns in every long story. Neither is failure. Naming which season you are in dissolves half the confusion — and half the loneliness that comes from misreading weather as character.",
  "Distance et proximité se succèdent dans toute longue histoire. Ni l'une ni l'autre n'est un échec. Nommer sa saison dissout la moitié de la confusion — et la moitié de la solitude née de prendre la météo pour du caractère.")

# --- AUTONOMY -----------------------------------------------------------------
k("theme.title.autonomy.1", "Elbow Room", "De la place pour respirer")
k("theme.title.autonomy.2", "Room to Arrive", "La place pour arriver")
k("theme.title.autonomy.3", "The Space Where Choice Lives", "L'espace où le choix vit")
k("theme.discover.autonomy.1",
  "Wanting needs room to arrive into. An hour with no agenda is not an empty hour; it is an open door. Desire rarely knocks on a door that is already full.",
  "Le désir a besoin de place pour arriver. Une heure sans programme n'est pas une heure vide ; c'est une porte ouverte. Le désir frappe rarement à une porte déjà pleine.")
k("theme.discover.autonomy.2",
  "Autonomy is not distance. It is the space where choice still lives — and choice is where wanting becomes possible. Removing expectation is itself an invitation; pressure is the opposite of appetite.",
  "L'autonomie n'est pas la distance. C'est l'espace où le choix vit encore — et le choix rend le désir possible. Retirer l'attente est en soi une invitation ; la pression est l'opposée de l'appétit.")
k("theme.discover.autonomy.3",
  "No is a complete sentence, and it protects yes. Each time you decline what you do not want, the things you choose gain weight. Today, protect one small yes with a clear no.",
  "Non est une phrase complète, et elle protège oui. Chaque fois que vous refusez ce que vous ne voulez pas, ce que vous choisissez prend du poids. Aujourd'hui, protégez un petit oui par un non clair.")
