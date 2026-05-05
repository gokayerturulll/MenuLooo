// src/routes/menubot.routes.js
// MenuBot AI Chatbot API'si
// PostgreSQL JSONB ile sohbet geçmişi saklanır.
const express = require('express');
const router = express.Router();
const { query } = require('../../config/database');
const { authMiddleware } = require('../middleware/auth.middleware');
const { v4: uuidv4 } = require('uuid');

/**
 * POST /api/menubot/chat
 * Kullanıcıdan gelen mesajı işle, yanıt üret ve JSONB'ye kaydet.
 *
 * İlerleyen aşamalarda bu endpoint Python AI servisine proxy yapacak.
 * Şimdilik kural tabanlı basit yanıtlar döner.
 */
router.post('/chat', authMiddleware, async (req, res) => {
  try {
    const { message, context } = req.body;
    const userId = req.user.id;

    // Kullanıcının mevcut konuşmasını bul ya da yeni oluştur
    let convResult = await query(
      'SELECT id, messages FROM menubot_conversations WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1',
      [userId]
    );

    let convId, messages;
    if (convResult.rows.length === 0) {
      // İlk mesaj — yeni konuşma oluştur
      const newConv = await query(
        `INSERT INTO menubot_conversations (id, user_id, messages, context)
         VALUES ($1, $2, '[]'::jsonb, $3::jsonb) RETURNING id, messages`,
        [uuidv4(), userId, JSON.stringify(context || {})]
      );
      convId = newConv.rows[0].id;
      messages = [];
    } else {
      convId = convResult.rows[0].id;
      messages = convResult.rows[0].messages;
    }

    // Kullanıcı mesajını ekle
    const userMsg = { role: 'user', content: message, ts: new Date().toISOString() };
    messages.push(userMsg);

    // ── AI Yanıt Üretimi ──────────────────────────────
    // TODO: Python AI servisine HTTP isteği (Aşama 5'te)
    // Şimdilik kural tabanlı yanıt
    const botReply = await generateBotReply(message, context, userId);
    const botMsg = { role: 'bot', content: botReply.text, data: botReply.data, ts: new Date().toISOString() };
    messages.push(botMsg);

    // Güncellenmiş mesajları JSONB'ye kaydet
    await query(
      'UPDATE menubot_conversations SET messages = $1::jsonb, updated_at = NOW() WHERE id = $2',
      [JSON.stringify(messages), convId]
    );

    res.json({
      conversation_id: convId,
      reply: botMsg,
      suggestions: botReply.suggestions || []
    });
  } catch (err) {
    console.error('MenuBot hatası:', err);
    res.status(500).json({ error: 'MenuBot yanıt veremedi.' });
  }
});

// GET /api/menubot/history — Sohbet geçmişi
router.get('/history', authMiddleware, async (req, res) => {
  try {
    const result = await query(
      `SELECT id, messages, created_at, updated_at
       FROM menubot_conversations
       WHERE user_id = $1
       ORDER BY updated_at DESC LIMIT 10`,
      [req.user.id]
    );
    res.json({ conversations: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Geçmiş alınamadı.' });
  }
});

// DELETE /api/menubot/history — Sohbet geçmişini temizle
router.delete('/history', authMiddleware, async (req, res) => {
  try {
    await query('DELETE FROM menubot_conversations WHERE user_id = $1', [req.user.id]);
    res.json({ message: 'Sohbet geçmişi temizlendi.' });
  } catch (err) {
    res.status(500).json({ error: 'Geçmiş temizlenemedi.' });
  }
});

// ── Kural tabanlı geçici bot yanıt motoru ───────────────
async function generateBotReply(message, context, userId) {
  const msg = message.toLowerCase();

  // Bütçe sorusu
  if (msg.includes('bütçe') || msg.includes('fiyat') || msg.includes('ucuz')) {
    return {
      text: 'Bütçeni belirtirsen sana uygun restoranları ve menü öğelerini listeleyebilirim. Ne kadar harcamak istiyorsun?',
      suggestions: ['50 TL altı', '100-200 TL arası', '200 TL üzeri']
    };
  }

  // Diyet sorusu
  if (msg.includes('vegan') || msg.includes('vejetaryen') || msg.includes('glutensiz')) {
    const { query: dbQuery } = require('../../config/database');
    const filter = msg.includes('vegan') ? 'is_vegan' :
                   msg.includes('vejetaryen') ? 'is_vegetarian' : 'is_gluten_free';
    const items = await dbQuery(
      `SELECT mi.name, mi.price, r.name as restaurant
       FROM menu_items mi JOIN restaurants r ON r.id = mi.restaurant_id
       WHERE mi.${filter} = TRUE AND mi.is_available = TRUE
       ORDER BY RANDOM() LIMIT 5`
    );
    const itemList = items.rows.map(i => `• ${i.name} — ${i.price}₺ (${i.restaurant})`).join('\n');
    return {
      text: `İşte senin için ${filter.replace('is_', '')} seçenekler:\n\n${itemList || 'Şu an uygun seçenek bulunamadı.'}`,
      data: items.rows
    };
  }

  // Yakın restoran
  if (msg.includes('yakın') || msg.includes('yakında') || msg.includes('en iyi')) {
    return {
      text: 'Konumunu paylaşırsan yakınındaki en iyi restoranları haritada gösterebilirim!',
      suggestions: ['Konumumu paylaş', 'Haritayı aç']
    };
  }

  // Genel karşılama
  return {
    text: 'Merhaba! Ben MenuBot 🤖 Sana ne konuda yardımcı olabilirim? Restoran önerisi, bütçeye uygun menü veya diyet tercihlerine göre filtreleme yapabilirim.',
    suggestions: ['Bütçeme göre öneri', 'Vegan seçenekler', 'Yakımdaki restoranlar']
  };
}

module.exports = router;
