"
I record that a standing activation's wait was cancelled: the strand it was parked on
fell (FBFlowInstance>>cancelStrand:), so it will not be resumed. The activation stays in
the log and reads #cancelled off its token; I am the moment that happened. Carries
scope, split and token like every FBNodeActivationEvent.
"
Class {
	#name : 'FBNodeActivationCancelled',
	#superclass : 'FBNodeActivationEvent',
	#category : 'FluxBase-Core-Event',
	#package : 'FluxBase-Core',
	#tag : 'Event'
}

{ #category : 'printing' }
FBNodeActivationCancelled >> message [
	^ 'activation cancelled'
]

{ #category : 'printing' }
FBNodeActivationCancelled >> printOn: aStream [ 
	super printOn: aStream.
	aStream << ' cancelled'
]

{ #category : 'accessing' }
FBNodeActivationCancelled >> type [
	^ #activationCancelled
]
