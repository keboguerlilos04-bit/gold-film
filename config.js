// =====================================================================
//  Konfigirasyon app la
//  Kopye "Project URL" ak kle "anon / publishable" Supabase ou a isit la.
//  (Supabase > Project Settings > API)
//  Si de premye chan yo vid, app la louvri an MÒD DEMO.
//  To dola a pa la: ou chanje l nan app la (seksyon Lajan).
// =====================================================================
window.APP_CONFIG = {
  SUPABASE_URL: 'https://vtovrsrzfokjgvaykgdq.supabase.co',
  SUPABASE_ANON_KEY: 'sb_publishable_foFlb20vb7NiCGb-fTjUKA_cln8L41w',

  BUSINESS_NAME: 'Gold Film', // non ki parèt nan app la ak nan mesaj yo
  DEFAULT_CURRENCY: 'HTG', // lajan pa defo pou pri yon nouvo kliyan (HTG oswa USD)
  DEFAULT_PRICE: 0,        // pri pa defo pou yon nouvo kliyan
  COUNTRY_CODE: '509',     // ajoute devan nimewo 8 chif pou WhatsApp
  DUE_SOON_DAYS: 3,        // konbyen jou anvan dat kliyan an pou rapèl "talè"
  CARD_ALERT_DAYS: 7,      // konbyen jou anvan Netflix retire kòb pou alèt kat kado
  SERVICE_NAME: 'Netflix'  // non sèvis la nan mesaj WhatsApp yo
};
