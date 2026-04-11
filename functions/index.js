const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.assignRole = functions.https.onCall(async (data, context) => {

//  // Security: only allow logged-in users
//  if (!context.auth) {
//    throw new functions.https.HttpsError(
//      "unauthenticated",
//      "You must be logged in"
//    );
//  }

  const uid = data.uid;
  const role = data.role;
  const club = data.club;

  // Extra safety check
//  if (role !== "admin" && role !== "user") {
//    throw new functions.https.HttpsError(
//      "invalid-argument",
//      "Role must be admin or user"
//    );
//  }

  await admin.auth().setCustomUserClaims(uid, { 'admin' : role,'club-name' : club });

  return { success: true, assignedRole: role };
});
