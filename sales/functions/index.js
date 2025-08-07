const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

exports.notifySalesmanOnOrderStatusChange = onDocumentUpdated('Orders/{orderId}', async (event) => {
  const beforeStatus = event.data.before.get('order_status');
  const afterStatus = event.data.after.get('order_status');

  const validStatuses = ['pending', 'accepted', 'sent out for delivery', 'delivered'];

  if (
    beforeStatus !== afterStatus &&
    validStatuses.includes(beforeStatus) &&
    validStatuses.includes(afterStatus)
  ) {
    const db = getFirestore();
    const orderData = event.data.after.data();

    const salesmanId = orderData.salesmanID;

    // Get salesman's FCM token
    const salesmanDoc = await db.collection('users').doc(salesmanId).get();
    const fcmToken = salesmanDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log("No FCM token found for salesman:", salesmanId);
      return;
    }

    // Get order ID for context (optional)
    const orderId = orderData.orderId || 'Order';


    // Create a custom message based on order status
    let statusMessage = '';
    switch (afterStatus) {
      case 'pending':
        statusMessage = `Order #${orderId} has been marked as pending.`;
        break;
      case 'accepted':
        statusMessage = `Order #${orderId} has been accepted.`;
        break;
      case 'sent out for delivery':
        statusMessage = `Order #${orderId} is out for delivery.`;
        break;
      case 'delivered':
        statusMessage = `Order #${orderId} has been delivered.`;
        break;
      default:
        statusMessage = `Order #${orderId} status changed to "${afterStatus}".`;
        break;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: 'Order Status Updated',
        body: statusMessage,
      },
    };

    await getMessaging().send(message);
    console.log("Notification sent to salesman:", salesmanId);
  } else {
    console.log("No valid status change detected.");
  }
});
