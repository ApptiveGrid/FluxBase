Class {
	#name : 'FBRecordingTransitionActivation',
	#superclass : 'FBActivation',
	#classInstVars : [
		'recorded'
	],
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'recording' }
FBRecordingTransitionActivation class >> recorded [
	^ recorded ifNil: [ recorded := OrderedCollection new ]
]

{ #category : 'recording' }
FBRecordingTransitionActivation class >> reset [
	recorded := OrderedCollection new
]

{ #category : 'as yet unclassified' }
FBRecordingTransitionActivation >> transitionMatches: aTransition [
	self class recorded add: aTransition.
	^ super transitionMatches: aTransition
]
