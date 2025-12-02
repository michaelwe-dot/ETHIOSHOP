const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onChatMessage = functions.firestore.document('threads/{threadId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const threadId = context.params.threadId;

    const threadSnap = await admin.firestore().collection('threads').doc(threadId).get();
    const thread = threadSnap.data();
    const participants = thread.participants || [];

    const senderId = message.from;
    const otherUsers = participants.filter(uid => uid !== senderId);

    let tokens = [];
    for (const uid of otherUsers) {
      const u = await admin.firestore().collection('users').doc(uid).get();
      const data = u.data();
      if (data && data.tokens) {
        tokens.push(...data.tokens);
      }
    }
    if (tokens.length === 0) return null;

    const payload = {
      notification: {
        title: 'New message',
        body: message.text ? message.text : '📷 Image received',
      },
      data: {
        type: 'chat',
        threadId: threadId,
      }
    };

    await admin.messaging().sendToDevice(tokens, payload);
    return null;
  });

exports.onNewListing = functions.firestore.document('listings/{listingId}')
  .onCreate(async (snapshot, context) => {
    const listing = snapshot.data();

    const usersSnap = await admin.firestore().collection('users').get();
    let tokens = [];
    usersSnap.forEach(doc => {
      const data = doc.data();
      if (data.tokens) tokens.push(...data.tokens);
    });
    if (tokens.length === 0) return null;

    const payload = {
      notification: {
        title: 'New listing posted',
        body: `${listing.title} — ETB ${listing.price}`,
      },
      data: {
        type: 'listing',
        listingId: context.params.listingId,
      }
    };

    await admin.messaging().sendToDevice(tokens, payload);
    return null;
  });
