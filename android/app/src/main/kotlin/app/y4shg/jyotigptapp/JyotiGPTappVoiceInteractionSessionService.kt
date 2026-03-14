package app.y4shg.jyotigptapp

import android.service.voice.VoiceInteractionSession
import android.service.voice.VoiceInteractionSessionService
import android.os.Bundle

class JyotiGPTappVoiceInteractionSessionService : VoiceInteractionSessionService() {
    override fun onNewSession(args: Bundle?): VoiceInteractionSession {
        return JyotiGPTappVoiceInteractionSession(this)
    }
}
