"
I am one queued step in an executor: a transition that is due to be followed,
together with the FBToken that should be handed to the activation it produces.

I exist because a transition alone is not enough to schedule work. The token
carries the branch identity that FBJoinBehavior needs later (see FBToken), so it
has to survive the trip through the pending queue rather than being recreated at
the far end.

Every executor queues its work as me: FBBaseExecutor>>addPending:withToken: is
the single writer of #pending, so a transition and its token cannot come apart
on the way through the queue. A parallel scope's body is the one thing queued
without a token of its own, because the executor - not an activation - queues
it; FBParallelExecutor>>scopeToken mints the fork's child token for it when the
work item is taken off the queue.

A #pending entry read back out of an old store can still be a raw FBTransition,
from before I existed. FBTransition>>transition duck-types as me for those.
"
Class {
	#name : 'FBWorkItem',
	#superclass : 'Object',
	#instVars : [
		'transition',
		'token',
		'value'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'as yet unclassified' }
FBWorkItem >> token [
	^ token
]

{ #category : 'as yet unclassified' }
FBWorkItem >> token: aFBToken [
	token := aFBToken
]

{ #category : 'as yet unclassified' }
FBWorkItem >> transition [
	^ transition
]

{ #category : 'as yet unclassified' }
FBWorkItem >> transition: aFBTransition [
	transition := aFBTransition
]

{ #category : 'as yet unclassified' }
FBWorkItem >> value [
	^ value
]

{ #category : 'as yet unclassified' }
FBWorkItem >> value: anObject [
	value := anObject
]
