# Emitters

Emitters play all `Sound` objects inside of them and emit all `ParticleEmitter` objects inside of them when touched.

## Use Cases

Emitters can be used for cinematic effects and gameplay cues. They can be limited by the
`Uses` configuration as to not emit more than the specified number of times.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `GlobalSound` | true | Whether `Sound` instances should play globally or spatially from the Emitter.
| `Uses` | Infinite | How many times the Emitter can be used. Every time the emitter is used, this value is decremented.
| `Cooldown` | 1 | Time in seconds to wait before the Emitter can activate again
