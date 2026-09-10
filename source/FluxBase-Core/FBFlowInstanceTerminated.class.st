"
I record that an instance was terminated from inside: an FBTerminateEvent was reached,
and every other strand of the instance was taken back (FBFlowInstance>>terminateExcept:).
A modelled end, not a cancellation - the instance goes on to end as #done, the strands
taken leave an FBNodeActivationCancelled each where an activation stood on a wait.
"
Class {
	#name : 'FBFlowInstanceTerminated',
	#superclass : 'FBFlowInstanceEvent',
	#category : 'FluxBase-Core-Event',
	#package : 'FluxBase-Core',
	#tag : 'Event'
}

{ #category : 'printing' }
FBFlowInstanceTerminated >> message [
	^ 'instance terminated'
]

{ #category : 'printing' }
FBFlowInstanceTerminated >> printOn: aStream [ 
	super printOn: aStream.
	aStream << 'instance terminated'
]

{ #category : 'accessing' }
FBFlowInstanceTerminated >> type [
	^ #instanceTerminated
]
