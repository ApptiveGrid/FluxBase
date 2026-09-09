Class {
	#name : 'FBWorkItemTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBWorkItemTest >> testAccessorsRoundTrip [
	| item transition token |
	transition := FBTransition new.
	token := FBToken new.
	item := FBWorkItem new
		transition: transition;
		token: token;
		yourself.
	self assert: item transition equals: transition.
	self assert: item token equals: token
]
