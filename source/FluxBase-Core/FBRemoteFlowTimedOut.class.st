"
The value that reaches an FBRemoteFlowTask in place of a result when its #maxWait ran
out: whoever fires the deadline - a schedule in the environment - signals me on the
wait's correlationId, and the task takes its #timedOut transition
(FBRemoteFlowTask>>resumeIn:withToken:value:). A callback arriving after me finds the
address consumed and is silent; so is a schedule firing after the callback.
"
Class {
	#name : 'FBRemoteFlowTimedOut',
	#superclass : 'Object',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'printing' }
FBRemoteFlowTimedOut >> printOn: aStream [
	aStream << 'remote flow timed out'
]
