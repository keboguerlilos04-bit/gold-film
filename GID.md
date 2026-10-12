# Gold Film — Gid enstalasyon ak itilizasyon

App pou jere kliyan, kont Netflix, kat kado, modpas, PIN ak lajan biznis la. Li mache sou telefòn kou sou òdinatè, an kreyòl oswa an franse, an mòd klè oswa nwa. Tout moun nan ekip la wè menm done yo an tan reyèl.

## Sa ki nan dosye a

| Fichye | Wòl li |
|---|---|
| `index.html` | App la li menm |
| `config.js` | Kle Supabase yo ak kèk paramèt (non biznis la, kòd peyi…) |
| `schema.sql` | Baz done a: tab yo, wòl yo, règ sekirite yo, kalkil otomatik yo |
| `manifest.webmanifest`, `sw.js`, `icon*` | Pou app la ka enstale sou telefòn |

> **Mòd demo:** si `config.js` pa gen kle Supabase, app la louvri ak done egzanp. Louvri `index.html` nan VS Code ak "Live Server" pou eseye l. Nan Paramèt, "Wè app la kòm" pèmèt ou wè sa chak moun nan ekip la wè.

---

## Etap enstalasyon (se ou ki fè yo, yon sèl fwa)

### 1. Kreye pwojè Supabase la (gratis, san kat bank)
1. Ale sou **supabase.com** → **Start your project** → konekte ak **GitHub**.
2. **New project**: non `gold-film`, chwazi yon modpas solid pou baz done a (kenbe l yon kote ki an sekirite), chwazi rejyon ki pi pre a, epi kreye l. Tann 1-2 minit.

### 2. Kreye tab yo
1. Nan meni agoch la, ale nan **SQL Editor** → **New query**.
2. Kole **tout** kontni `schema.sql`, epi peze **Run**. Ou dwe wè "Success".

### 3. Paramèt koneksyon yo
Nan **Authentication → Sign In / Providers** (oswa **Providers → Email**):
- Kite **Email** aktive, ak **"Allow new users to sign up"** aktive (moun nan ekip la ap enskri poukont yo).
- Dezaktive **"Confirm email"**. Konsa moun yo ka konekte tousuit apre yo enskri, san tann yon imèl.

Pa gen danje: yon moun ki enskri pa wè anyen toutotan pwopriyetè prensipal la pa ba l yon wòl.

### 4. Konekte app la ak Supabase
1. Ale nan **Project Settings → API** (oswa **Data API**).
2. Kopye **Project URL** ak kle **anon / publishable** la.
3. Kole yo nan `config.js`:

```js
SUPABASE_URL: 'https://xxxx.supabase.co',
SUPABASE_ANON_KEY: 'eyJ...',
```

Kle "anon" sa a ka parèt piblikman: se règ sekirite `schema.sql` yo ki pwoteje done yo. **Pa janm** mete kle "service_role" la nan app la.

### 5. Mete app la anliy
**Opsyon A — GitHub Pages** (ou deja gen GitHub):
1. Kreye yon nouvo repo (egz: `gold-film`) epi voye tout fichye dosye a ladan l.
2. **Settings → Pages** → Source: branch `main`, dosye `/ (root)` → **Save**.
3. Apre 1-2 minit, app la disponib sou `https://<non-ou>.github.io/gold-film/`.

Sou plan gratis GitHub la, repo a dwe **piblik** pou Pages. Pa gen sekrè nan fichye yo, men si w pito repo a prive, sèvi ak opsyon B.

**Opsyon B — Cloudflare Pages** (repo a ka prive): kreye yon kont gratis, **Workers & Pages → Create → Pages → Connect to Git**, chwazi repo a, kite "Build command" vid, epi pibliye.

### 6. Enskri an premye (enpòtan!)
Louvri adrès app la, peze **Enskri**, epi kreye kont ou. **Premye moun ki enskri a vin pwopriyetè prensipal (P1) otomatikman.** Fè sa tousuit apre w fin mete app la anliy, anvan w bay lòt moun adrès la.

### 7. Enstale l sou telefòn
Louvri adrès la nan **Chrome** → meni (⋮) → **Enstale app** / **Ajoute sou ekran dakèy**.

### 8. Premye bagay nan app la
1. **Lajan → To → Chanje:** mete to dola a.
2. **Kont → +:** ajoute chak kont ak imèl li, pri plan an, pri yon manm siplemantè, ak pwochen dat retrè Netflix.
3. Nan chak kont: **Mete modpas la** → Konfime, **+ Kat kado**, **+ Ajoute** manm siplemantè si genyen.
4. **Kliyan → +:** ajoute kliyan yo, ak lang mesaj yo (Kreyòl oswa Français).
5. **Ekip:** voye adrès app la bay asosye w yo ak lòt pwopriyetè yo. Yo enskri, epi nan **Paramèt → Jere ekip la**, ou ba yo wòl yo.

---

## Ekip: pwopriyetè ak asosye

- Jiska **3 pwopriyetè** (P1, P2, P3) ak **3 asosye** (A1, A2, A3).
- **P1 (prensipal)** se sèl moun ki ka aksepte yon moun, chanje wòl li, oswa retire l.
- Kòd chak moun (P1, A2…) parèt nan istwa yo: ki moun ki anrejistre yon peman, chanje yon PIN, oswa konfime yon modpas.

| | Pwopriyetè | Asosye |
|---|:-:|:-:|
| Wè kliyan ak kont | ✅ | ✅ |
| Ajoute / modifye kliyan, anrejistre peman | ✅ | ✅ |
| Voye modpas, PIN, rapèl, konfimasyon | ✅ | ✅ |
| Jenere / konfime modpas, mete PIN | ✅ | ✅ |
| Efase kliyan | ✅ | ❌ |
| Kont, plas siplemantè, kat kado, to dola | ✅ | ❌ |
| Wè lajan (peman, kat, benefis) | ✅ | ❌ |
| Jere ekip la | P1 sèlman | ❌ |

## Kliyan

- Peze sou non yon kliyan pou louvri **fich li**: modpas, rapèl, peman, PIN.
- Bouton **🔑** bò kote chak kliyan aktif voye **imèl + modpas kont li** sou WhatsApp. Chak mesaj parèt anvan w voye l, ak yon bouton **Kopye**.
- Kliyan **an poz** pa gen bouton 🔑: li pa ka resevwa modpas la.
- **Lang mesaj:** chak kliyan resevwa mesaj yo nan lang li chwazi a (Kreyòl oswa Français), kèlkeswa lang app la.

## PIN

- Ou tape PIN nan alamen (4 chif), **2 fwa** pou evite erè. App la pa jenere PIN.
- Apre li anrejistre, **pèsonn pa ka chanje l pandan 3 jou**. Fich la montre "Bloke jiska…".
- Apre w anrejistre l, app la pwopoze w voye l bay kliyan an tousuit.
- Pou chanje kantite jou blokaj la, kouri sa nan SQL Editor (egz: 2 jou):
  ```sql
  update public.settings set pin_lock_days = 2;
  ```

## Modpas kont yo

1. **Jenere nouvo** → li rete **an atant**; modpas aktif la pa chanje.
2. Chanje l sou Netflix (kont prensipal la ak manm siplemantè yo).
3. **Konfime** → nouvo a vin aktif. Si w pa t ka chanje l, **Anile**.

App la kenbe modpas aktif la + 2 ansyen. Moun ki deja konekte sou Netflix yo ap rete konekte: nouvo modpas la anpeche sèlman nouvo koneksyon. Pou voye l bay yon kliyan, sèvi ak bouton 🔑 bò kote kliyan an.

## Peman

Lè w konfime yon peman, app la montre yon **resi** ak bouton **"Voye konfimasyon"**: kliyan an resevwa montan an, pou konbyen mwa, ak dat abònman li valab la.

## Kat kado ak balans

- Chak kont gen yon **balans** an dola. Lè w ajoute yon kat, li monte; chak lè dat Netflix la rive, app la retire pri mwa a otomatikman.
- Lè w ap ajoute yon kat, app la di w sa li kouvri (`$27 = 2 mwa egzak`).
- **Konbyen pou m achte?** kalkile montan egzak la. **Korije balans** mete balans lan menm jan ak Netflix.
- **Manm siplemantè** ka peye "sou kat kont lan" (pri a ajoute sou kont lan) oswa "ak pwòp kat pa l" (balans pa l).
- Alèt sou paj Jodi a 7 jou anvan yon kont manke kòb.

## Lajan (pwopriyetè sèlman)

- **Yon mwa:** antre, kat achte, benefis, ak ki moun ki anrejistre chak peman.
- **Mwayèn:** chwazi dènye mwa a ak kantite mwa; app la montre chak mwa, mwayèn lan ak total la.
- Chak peman ak chak kat kenbe **to jou yo te fèt la**, kidonk chanje to a pa chanje ansyen kalkil yo.

## Paramèt (⚙ anlè adwat)

- **Lang app la:** Kreyòl oswa Français.
- **Aparans:** Otomatik (swiv telefòn nan), Klè, oswa Nwa.
- Chak moun chwazi pou pwòp telefòn pa l.

## Bon pou konnen

- Modpas ak PIN yo nan baz done a: se sèlman moun nan ekip la ki ka wè yo. Pa bay pèsonn aksè nan pwojè Supabase la.
- Yon pwojè Supabase gratis ka **mete an poz** si li pa itilize pandan yon semèn. Si nou itilize app la chak jou, sa p ap rive.
- Si w modifye app la epi telefòn yo pa wè chanjman yo, chanje non cache a nan `sw.js` (`goldfilm-v4` → `goldfilm-v5`).
