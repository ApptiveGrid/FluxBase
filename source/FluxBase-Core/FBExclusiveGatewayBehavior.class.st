Class {
	#name : 'FBExclusiveGatewayBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBExclusiveGatewayBehavior >> execute [
	| matching defaults |
	activation value: self argument.
	activation done.
	matching := self outgoing select: [ :each |
		each hasCondition and: [ activation transitionMatches: each ] ].
	matching size = 1 ifTrue: [ ^ self followTransition: matching first ].
	matching size > 1 ifTrue: [
		^ FBAmbiguousTransition signal: 'more than one outgoing transition matched on an exclusive gateway' ].
	defaults := self outgoing reject: #hasCondition.
	defaults size = 1 ifTrue: [ ^ self followTransition: defaults first ].
	defaults isEmpty ifTrue: [
		^ FBNoMatchingTransition signal: 'no outgoing transition matched on an exclusive gateway and no default transition exists' ].
	^ FBAmbiguousTransition signal: 'more than one default (unconditioned) outgoing transition exists on an exclusive gateway'
]
