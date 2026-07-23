Class {
	#name : 'FBTransitionTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBTransitionTest >> testTransitionAnswersItselfForDuckTypingWithWorkItem [
	| transition |
	transition := FBTransition new.
	self assert: transition transition == transition
]
