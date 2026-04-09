+++
title = "A New Dynamical System Model of Mind"
date = 2026-04-07
+++

Here I present a novel model of Buddhist theory on mind and reality using the language of dynamical systems.

The goal of this article is not to force a scientific equivalence, but to build an intuitive bridge for those familiar with systems theory, machine learning, and nonlinear dynamics with the core teachings of the Buddha.

The central shift is simple. Instead of asking what exists, where karma is stored, how it is tranferred between rebirths, we ask how *processes* evolve over time.

There is no container for karma. There is only dependent continuity of transformation.

The central claim is that the Buddhist account of the mental stream and the path of liberation can be faithfully represented as a discrete-time, partially observable, non-stationary, self-modifying stochastic dynamical system operating on a stratified state space.

---

## 1. The Stream as a Dynamical System

Before going further, it helps to ground the idea of a dynamical system with simple examples.

A dynamical system is anything that evolves over time according to rules.

Examples:

* A pendulum swinging back and forth
* Weather systems changing day by day
* A neural network updating its weights during training
* A thermostat adjusting temperature based on feedback

In each case:

* There is a current state
* There is a rule for how the next state is produced

This can be written as:

```
S(t+1) = F(S(t))
```

Where:

* `S(t)` is the current state
* `F` is the rule that generates the next state

Some systems are simple and predictable. Others are chaotic and sensitive to small changes.

It is thus very natural to think of the mind, in this model, as a very high dimensional dynamical system.

What is traditionally called the stream of consciousness can be modeled as a state evolving over time:

```
S(t+1) = F(S(t), conditions)
```

* `S(t)` represents the current mental configuration
* `F` is the transition function shaped by past conditioning
* `conditions` include sensory input and internal tendencies

There is no hidden storage layer. The past is not stored somewhere else. It is encoded in the structure of the present state itself.

This is similar to a Markov process, but with an important nuance. The system behaves as if it is Markovian because the *present* sufficiently encodes the *past*, even though the history that formed it may be deep and complex.

---

## 2. Karma as State Conditioning

Karma is not a substance. It is not stored in the body or in a metaphysical container.

Karma is the way past transitions shape the current transition function.

In practical terms:

* Actions modify the system
* Repetition strengthens certain transitions
* Tendencies emerge as biases in evolution

Latent karma is simply the set of dispositions embedded in the current state.

There is no queue of actions waiting to execute. There is only a field of potential responses, with some more likely than others depending on conditions.

---

## 3. Chaos and Stochasticity

The system is neither purely deterministic nor purely random.

It has two key properties:

### Sensitivity to Initial Conditions

Small changes can lead to large downstream effects. A minor intention can reshape long term behavior.

### Conditional Activation

Not all tendencies manifest. Which one activates depends on present conditions.

This leads to a hybrid model:

* Nonlinear dynamics govern evolution
* Probabilistic activation determines which tendencies arise

A useful intuition is that of competing attractors.

---

## 4. Attractors and Habit Formation

Mental habits behave like attractor basins.

* Anger is an attractor
* Desire is an attractor
* Calm is an attractor

The system tends to fall into these basins when conditions align.

Practice reshapes this landscape:

* Weakening certain attractors
* Strengthening others

Over time, the default trajectory of the system changes.

---

## 5. Jhāna as Attractor Stabilization

Jhāna can be understood as highly stable attractor states.

Before stabilization:

* The system is noisy
* It jumps between multiple basins

In jhāna:

* The system locks into a single basin
* Perturbations have minimal effect

Each factor of jhāna plays a role in stabilizing the system:

* Applied attention initializes the state
* Sustained attention maintains it
* Joy amplifies signal strength
* Contentment reduces instability
* One pointedness reduces dimensionality

As one progresses through deeper stages, fewer factors are required. The system becomes self stabilizing.

---

## 6. Vipassanā as Attractor Dissolution

Insight practice does not create a better attractor. It undermines the entire structure.

Through direct observation, three characteristics become clear:

* All states are unstable
* No state is ultimately satisfying
* No state belongs to a self

This leads to a collapse in attractor strength.

The system stops committing to basins. Transitions become fluid. Patterns lose their grip.

---

## 7. Fetters as Constraints on State Space

The ten fetters can be modeled as constraints on the accessible state space.

They do not just bias behavior. They limit what is even possible.

Examples:

* Identity view forces self referential processing
* Sensual desire reinforces low level attractors
* Ignorance distorts the entire landscape

Removing fetters expands accessible states.

At early awakening, some constraints are lifted. At full liberation, all constraints are gone.

---

## 8. Dependent Origination as System Dynamics

Dependent origination can be reframed as the recursive update rule of the system.

Each component plays a functional role:

* Ignorance shapes the model
* Formations define transition tendencies
* Consciousness represents current state
* Sensory contact provides input
* Feeling evaluates input
* Craving introduces directional bias
* Clinging locks states
* Becoming stabilizes trajectories

This is not a linear chain. It is a loop that continuously updates the system.

---

## 9. Death and Reinitialization

Death is not termination of the process. It is a boundary condition.

The system does not reset to zero. It transitions:

```
S_last -> S_0_new
```

The new configuration depends on dominant tendencies at the boundary.

Other latent tendencies remain embedded in the structure and can manifest later.

---

## 10. Liberation as Termination of Propagation

Ordinary systems continue to generate future states.

With full insight:

* Ignorance is removed
* Craving no longer drives movement
* Clinging no longer locks states

The system still evolves during life, but it no longer produces future propagation beyond the final boundary.

There is continuity without continuation.

---

## 11. Vēdanā to Taṇhā as Reward Learning

We can push the model further using reinforcement learning intuition.

At each moment, the system receives an evaluative signal:

* Vēdanā functions like a reward signal

  * pleasant -> positive reward
  * unpleasant -> negative reward
  * neutral -> weak or no signal

This signal updates the system's tendencies:

* Pleasant feeling -> increases probability of approach
* Unpleasant feeling -> increases probability of avoidance

This is structurally similar to a reward update rule:

```
Policy_{t+1} = Policy_t + learning_rate * reward_signal
```

Where:

* Policy corresponds to habitual responses
* Reward signal corresponds to vēdanā

Taṇhā arises as:

> the learned gradient that pushes the system toward maximizing pleasant states and minimizing unpleasant ones

So:

* Vēdanā = raw signal
* Taṇhā = learned directional bias

Clinging then acts as policy hardening. It reduces flexibility and locks the system into repeating specific trajectories.

---

## 12. Gradient Dynamics of Taṇhā

We can sharpen the reinforcement learning analogy further.

Taṇhā behaves like a gradient operator acting on the state space.

* Pleasant vēdanā induces gradient ascent
* Unpleasant vēdanā induces gradient descent

So the system evolves as if optimizing:

```
S(t+1) = S(t) + alpha * grad(reward)
```

Where:

* alpha is a learning rate
* grad(reward) is inferred from vēdanā

This creates directional movement in the state space:

* attraction toward pleasant configurations
* repulsion from unpleasant configurations

Clinging makes this worse by:

* increasing alpha
* reducing exploration

So the system becomes:

* more rigid
* more trapped in local patterns

---

## 13. Zero-Objective Dynamics

What happens if the reward signal is no longer used?

This is the key to understanding liberation.

In ordinary systems:

* behavior is driven by reward maximization

In the liberated system:

* vēdanā still arises
* but it is not converted into taṇhā

So:

* no gradient is formed
* no optimization step occurs

The system still evolves:

```
S(t+1) = F(S(t), conditions)
```

But without:

* reward chasing
* penalty avoidance

---

## 14. Nirvāṇa as Removal of the Optimization Objective

This is the most radical shift.

In all ordinary systems, behavior is driven by an implicit objective:

* maximize pleasure
* minimize pain
* stabilize identity

This can be thought of as an optimization problem.

With insight:

* pleasant states are seen as unstable
* unpleasant states are seen as unavoidable
* identity is seen as constructed

This breaks the validity of the objective itself.

So instead of improving the optimizer, something deeper happens:

> the optimization objective is dropped

In system terms:

* No reward chasing
* No penalty avoidance
* No policy reinforcement

The system continues to function, but:

* actions occur without accumulation of new bias
* states arise and pass without being optimized for

This is not passivity. It is the absence of compulsive optimization.

---

## 15. Final Synthesis

We can now restate the full model:

* State evolves through a nonlinear transition function
* Karma shapes that function over time
* Vēdanā provides reward signals
* Taṇhā encodes learned gradients
* Upādāna locks policies into place
* Bhava stabilizes trajectories into modes of existence

Practice works in two directions:

* Jhāna stabilizes the system
* Vipassanā removes the basis for optimization

Liberation is not reaching a better state.

It is the end of being driven to optimize states at all.

---

## Final Thoughts

This model does not claim that reality is literally a dynamical system. It uses that language to clarify something subtle.

1. There is no need for a container of karma.

2. There is only a process that shapes itself, moment by moment.

3. Understanding this is not merely intellectual. It changes how one relates to action, habit, and identity.

The system is not something you *have*. It is something that you are part of and is in action *right here, right now*.
