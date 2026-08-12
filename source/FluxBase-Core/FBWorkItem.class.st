"
I am one queued step in an executor: a transition that is due to be followed,
together with the FBToken that should be handed to the activation it produces.

I exist because a transition alone is not enough to schedule work. The token
carries the branch identity that FBJoinBehavior needs later (see FBToken), so it
has to survive the trip through the pending queue rather than being recreated at
the far end.

Note that only FBFlowExecutor actually wraps its pending entries in me.
FBBaseExecutor - and with it FBParallelExecutor - accepts a token in
#addPending:withToken: but drops it on the floor, so tokens do not survive
inside a parallel scope and every node there starts from a fresh default token.
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
FBWorkItem >> source [
	^ transition source
]

{ #category : 'as yet unclassified' }
FBWorkItem >> target [
	^ transition target
]

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
