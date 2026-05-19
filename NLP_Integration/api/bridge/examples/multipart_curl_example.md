# Voice Analyze Endpoint Example

```bash
curl -X POST "http://127.0.0.1:8000/triage/analyze-voice" \
  -H "Authorization: Bearer dev-token" \
  -F "audio_file=@sample.wav;type=audio/wav"
```

Expected response:

```json
{
  "transcript": "My chest hurts and I am sweating.",
  "triage_level": "Severe",
  "top_condition": "heart attack",
  "recommendation": "Evacuate immediately to nearest emergency-capable facility and monitor airway/breathing continuously."
}
```

