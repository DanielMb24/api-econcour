// Canonicalisation des numéros de téléphone (anti-doublons).
// Règle : deux écritures du même numéro (espaces, 00 ou + en préfixe)
// désignent le même numéro et ne peuvent pas créer deux comptes.
const normalizePhone = value => String(value || '').replace(/[\s().-]/g, '').replace(/^00/, '+');

// Variantes à tester en base : avec et sans '+' initial, pour retrouver
// les numéros enregistrés sous l'une ou l'autre forme.
const phoneVariants = (value) => {
  const normalized = normalizePhone(value);
  if (!normalized) return [];
  return normalized.startsWith('+') ? [normalized, normalized.slice(1)] : [normalized, `+${normalized}`];
};

module.exports = { normalizePhone, phoneVariants };
