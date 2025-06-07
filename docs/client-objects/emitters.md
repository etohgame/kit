# Emitters

Emitters plays all descendants `Sound` instances and emits all descendants
`ParticleEmitter` instances when touched.

Emitters can be limited by `Uses` as to not emit more than the specified
number of times.

## Use Cases

Emitters can be used for cinematic effects and gameplay cues.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `GlobalSound` | true | Whether `Sound` instances should play globally or spatially from the Emitter.
| `Uses` | Infinite | How many times the Emitter can be used. Every time the emitter is used, the `Uses` attribute is decremented.
| `Cooldown` | 1 | How long, in seconds, will the Emitter wait before it can be used again.
