# Emitters

Emitters play all `Sound` objects inside of them and emit all `ParticleEmitter` objects inside of them when touched.

## Use Cases

Emitters can be used for cinematic effects and gameplay cues. They can be limited by the
`Uses` configuration as to not emit more than the specified number of times.

`Sound` and `ParticleEmitter` objects have an optional `EmitDelay` attribute that specifies how long the Emitter should wait for before emitting those objects. `ParticleEmitter`s also have an optional `EmitCount` attribute that specifies how many particles to emit.

## Configuration

| Name | Default Value | Description
|:-----:|:-----:|:-----:
| `GlobalSound` | true | Whether `Sound` instances should play globally or spatially from the Emitter.
| `Uses` | 0 | How many times the Emitter can be used. Every time the emitter is used, this value is decremented. If set to 0, the Emitter will have infinite uses.
| `Cooldown` | 1 | Time in seconds to wait before the Emitter can activate again.
