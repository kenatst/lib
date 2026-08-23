import json

d = json.load(open('/Users/kena/ember/Ember/Resources/Localizable.xcstrings'))
keys = sorted(d.get('strings', {}))
print('total keys:', len(keys))
asym = [k for k in keys if k.startswith('couple.asymmetric')]
print('couple.asymmetric keys:', len(asym), asym[:6])
for probe in ['a11y.sketch.hero', 'home.title', 'welcome.cta', 'progress.days',
              'questions.counter', 'settings.version', 'couple.locked.other',
              'return.close.day', 'profile.lede.myDesire', 'selection.begin',
              'couple.switch.space', 'home.link.progress']:
    print(probe, '->', 'OK' if probe in keys else 'MISSING')
langs = set()
for v in d['strings'].values():
    langs.update(v.get('localizations', {}).keys())
print('languages:', sorted(langs))
print('sourceLanguage:', d.get('sourceLanguage'))
missing_days = []
for day in range(1, 22):
    for suffix in ['title', 'discover', 'reflect', 'act', 'returnPrompt']:
        k = f'day.{day}.{suffix}'
        if k not in keys:
            missing_days.append(k)
print('missing day keys:', missing_days if missing_days else 'none')
