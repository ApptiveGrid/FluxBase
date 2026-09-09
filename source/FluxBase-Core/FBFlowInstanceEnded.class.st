"
I mark the moment a flow instance is over: nothing pending, nothing suspended, the
root executor back on top. FBFlowInstance>>ended records me and drops the bookkeeping
of the run that has no meaning once it is over - see there for what falls.

An instance that waits has not ended and does not get me until it is resumed and runs
to its end. An instance that errored has stopped rather than ended and does not get me
either - FBNodeActivationErrored stays its last event.
"
Class {
	#name : 'FBFlowInstanceEnded',
	#superclass : 'FBFlowInstanceEvent',
	#category : 'FluxBase-Core-Event',
	#package : 'FluxBase-Core',
	#tag : 'Event'
}

{ #category : 'printing' }
FBFlowInstanceEnded >> message [
	^ 'instance ended'
]

{ #category : 'printing' }
FBFlowInstanceEnded >> printOn: aStream [ 
	super printOn: aStream.
	aStream << 'instance ended'
]

{ #category : 'accessing' }
FBFlowInstanceEnded >> type [

	^ #instanceEnded
]
