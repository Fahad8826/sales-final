
package com.techfifo.sales

import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.ktx.auth
import com.google.firebase.firestore.SetOptions
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase
import org.webrtc.*

class MicStreamService : Service() {

    private val TAG = "MicStreamService"
    private lateinit var peerConnectionFactory: PeerConnectionFactory
    private var peerConnection: PeerConnection? = null
    private lateinit var audioSource: AudioSource
    private lateinit var audioTrack: AudioTrack
    private lateinit var eglBase: EglBase

    private var callId: String? = null
    private var remoteSet = false
    private val firestore by lazy { Firebase.firestore }

    @Volatile
    private var isCreatingOffer = false
    private var lastOfferTimestamp = 0L
    private val offerCooldownMs = 30 * 1000L
    private var lastStatus: String? = null

    private val handler = Handler()
    private val refreshIntervalMs = 10 * 60 * 1000L
    private val refreshOfferRunnable = object : Runnable {
        override fun run() {
            Log.d(TAG, "🔄 Refreshing WebRTC offer")
            restartOffer()
            handler.postDelayed(this, refreshIntervalMs)
        }
    }

    private val restartReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "RESTART_OFFER") {
                Log.d(TAG, "🔁 Restart offer triggered by broadcast")
                restartOffer()
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "🔧 Service created")

        if (ActivityCompat.checkSelfPermission(this, android.Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "❌ Mic permission not granted. Stopping service.")
            stopSelf()
            return
        }

        FirebaseApp.initializeApp(this)
        startForegroundService()
        initializePeerConnectionFactory()
        startAudioStreaming()
        handler.postDelayed(refreshOfferRunnable, refreshIntervalMs)
        // registerReceiver(restartReceiver, IntentFilter("RESTART_OFFER"))
        val filter = IntentFilter("RESTART_OFFER")
        registerReceiver(restartReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
    }

   private fun startForegroundService() {
    val channelId = "mic_stream_service"
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel = NotificationChannel(
            channelId,
            "Mic Stream",
            NotificationManager.IMPORTANCE_LOW
        )
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    // Pick a daily quote
    val quotes = listOf(
        "“Believe in yourself.”",
        "“Stay positive, work hard, make it happen.”",
        "“Dream big and dare to fail.”",
        "“Success is not final, failure is not fatal.”",
        "“Do something today that your future self will thank you for.”"
    )
    val dayOfYear = java.util.Calendar.getInstance().get(java.util.Calendar.DAY_OF_YEAR)
    val quoteOfTheDay = quotes[dayOfYear % quotes.size]

    val notification = NotificationCompat.Builder(this, channelId)
        .setContentTitle("DIVYA SALES")
        .setContentText(quoteOfTheDay) 
        .setSmallIcon(R.drawable.app_icon)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .setStyle(
            NotificationCompat.BigTextStyle().bigText(quoteOfTheDay) 
        ).build()

    startForeground(1, notification)
    Log.d(TAG, "📢 Foreground service started with daily quote")
}


    private fun initializePeerConnectionFactory() {
        val options = PeerConnectionFactory.InitializationOptions.builder(this)
            .setEnableInternalTracer(true)
            .createInitializationOptions()
        PeerConnectionFactory.initialize(options)

        eglBase = EglBase.create()
        peerConnectionFactory = PeerConnectionFactory.builder()
            .createPeerConnectionFactory()
        Log.d(TAG, "✅ PeerConnectionFactory initialized")
    }

    private fun startAudioStreaming() {
        callId = Firebase.auth.currentUser?.uid
        if (callId == null) {
            Log.e(TAG, "❌ No user logged in")
            stopSelf()
            return
        }
        Log.d(TAG, "🎙 Starting mic streaming for user: $callId")

        val config = PeerConnection.RTCConfiguration(listOf(
            PeerConnection.IceServer.builder("stun:stun.l.google.com:19302").createIceServer()
        )).apply {
            sdpSemantics = PeerConnection.SdpSemantics.UNIFIED_PLAN
        }

        peerConnection = peerConnectionFactory.createPeerConnection(config, object : PeerConnection.Observer {
            override fun onIceCandidate(candidate: IceCandidate) {
                Log.d(TAG, "🧊 New ICE candidate: ${candidate.sdp}")
                firestore.collection("calls").document(callId!!).collection("callerCandidates")
                    .add(candidate.toMap())
            }

            override fun onIceConnectionChange(state: PeerConnection.IceConnectionState?) {
                Log.d(TAG, "❄ ICE connection state changed: $state")
            }

            override fun onIceConnectionReceivingChange(receiving: Boolean) {}
            override fun onAddStream(stream: MediaStream?) {}
            override fun onDataChannel(dc: DataChannel?) {}
            override fun onIceCandidatesRemoved(candidates: Array<out IceCandidate>?) {}
            override fun onIceGatheringChange(state: PeerConnection.IceGatheringState?) {}
            override fun onRemoveStream(stream: MediaStream?) {}
            override fun onRenegotiationNeeded() {}
            override fun onSignalingChange(state: PeerConnection.SignalingState?) {}
            override fun onTrack(transceiver: RtpTransceiver?) {}
            override fun onConnectionChange(newState: PeerConnection.PeerConnectionState?) {}
            override fun onSelectedCandidatePairChanged(event: CandidatePairChangeEvent?) {}
        })

        val audioConstraints = MediaConstraints()
        audioSource = peerConnectionFactory.createAudioSource(audioConstraints)
        audioTrack = peerConnectionFactory.createAudioTrack("audio", audioSource)
        peerConnection?.addTrack(audioTrack, listOf("stream1"))

        if (isCreatingOffer) {
            Log.d(TAG, "🚫 Offer creation already in progress, skipping")
            return
        }
        isCreatingOffer = true

        val mediaConstraints = MediaConstraints().apply {
            mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveAudio", "false"))
            mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveVideo", "false"))
        }

        peerConnection?.createOffer(object : SdpObserver {
            override fun onCreateSuccess(desc: SessionDescription) {
                peerConnection?.setLocalDescription(object : SdpObserver {
                    override fun onSetSuccess() {
                        isCreatingOffer = false
                        firestore.collection("calls").document(callId!!)
                            .set(mapOf(
                                "offer" to mapOf(
                                    "type" to desc.type.canonicalForm(),
                                    "sdp" to desc.description
                                ),
                                "status" to "waiting"
                            ), SetOptions.merge())
                        listenForAnswer()
                        listenForIceCandidates()
                        listenForDisconnectStatus()
                    }

                    override fun onSetFailure(msg: String?) { isCreatingOffer = false }
                    override fun onCreateSuccess(p0: SessionDescription?) {}
                    override fun onCreateFailure(p0: String?) {}
                }, desc)
            }

            override fun onCreateFailure(msg: String?) { isCreatingOffer = false }
            override fun onSetSuccess() {}
            override fun onSetFailure(msg: String?) {}
        }, mediaConstraints)
    }

    private fun restartOffer() {
        val now = System.currentTimeMillis()
        if (now - lastOfferTimestamp < offerCooldownMs) {
            Log.d(TAG, "⏱ Skipping restartOffer due to cooldown (${now - lastOfferTimestamp}ms elapsed)")
            return
        }

        Log.d(TAG, "♻ Restarting offer at $now")
        lastOfferTimestamp = now

        peerConnection?.close()
        remoteSet = false

        callId?.let { id ->
            val callRef = firestore.collection("calls").document(id)
            callRef.collection("callerCandidates").get()
                .addOnSuccessListener { snapshot ->
                    snapshot.documents.forEach { it.reference.delete() }
                    callRef.delete().addOnSuccessListener {
                        Log.d(TAG, "📞 Previous call data cleared, restarting stream")
                        startAudioStreaming()
                    }
                }
        }
    }

    private fun listenForDisconnectStatus() {
        firestore.collection("calls").document(callId!!)
            .addSnapshotListener { snapshot, _ ->
                val status = snapshot?.getString("status") ?: return@addSnapshotListener
                if (status == lastStatus) return@addSnapshotListener
                lastStatus = status

                if (status == "disconnected") {
                    resetCallAndRestart()
                }
            }
    }

    private fun listenForAnswer() {
        firestore.collection("calls").document(callId!!)
            .addSnapshotListener { snapshot, _ ->
                if (remoteSet || peerConnection == null) return@addSnapshotListener
                val answer = snapshot?.get("answer") as? Map<*, *> ?: return@addSnapshotListener
                val type = answer["type"] as? String ?: return@addSnapshotListener
                val sdp = answer["sdp"] as? String ?: return@addSnapshotListener
                val desc = SessionDescription(SessionDescription.Type.fromCanonicalForm(type), sdp)

                peerConnection?.setRemoteDescription(object : SdpObserver {
                    override fun onSetSuccess() {
                        remoteSet = true
                        firestore.collection("calls").document(callId!!).update("status", "connected")
                    }
                    override fun onSetFailure(msg: String?) {}
                    override fun onCreateSuccess(p0: SessionDescription?) {}
                    override fun onCreateFailure(p0: String?) {}
                }, desc)
            }
    }

    private fun listenForIceCandidates() {
        firestore.collection("calls").document(callId!!)
            .collection("calleeCandidates")
            .addSnapshotListener { snapshot, _ ->
                snapshot?.documentChanges?.forEach { change ->
                    val data = change.document.data
                    val sdpMid = data["sdpMid"] as? String ?: return@forEach
                    val sdpMLineIndex = (data["sdpMLineIndex"] as? Long)?.toInt() ?: return@forEach
                    val candidate = data["candidate"] as? String ?: return@forEach
                    peerConnection?.addIceCandidate(IceCandidate(sdpMid, sdpMLineIndex, candidate))
                }
            }
    }

    private fun resetCallAndRestart() {
        firestore.collection("calls").document(callId!!).delete()
            .addOnSuccessListener {
                remoteSet = false
                peerConnection?.close()
                startAudioStreaming()
            }
    }

    override fun onDestroy() {
        handler.removeCallbacks(refreshOfferRunnable)

        audioTrack.dispose()
        audioSource.dispose()
        peerConnection?.close()

        callId?.let { id ->
            val callRef = firestore.collection("calls").document(id)
            callRef.collection("callerCandidates").get()
                .addOnSuccessListener { snapshot ->
                    snapshot.documents.forEach { it.reference.delete() }
                    callRef.delete()
                }
        }

        unregisterReceiver(restartReceiver)

        super.onDestroy()
    }

    private fun IceCandidate.toMap(): Map<String, Any> = mapOf(
        "candidate" to sdp,
        "sdpMid" to sdpMid,
        "sdpMLineIndex" to sdpMLineIndex
    )
}