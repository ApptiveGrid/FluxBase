"
I record that a scope was cancelled (FBFlowInstance>>cancelScope:): from this moment on
nothing runs in it and nothing is taken in. The strands taken back with it leave their
own traces - an FBNodeActivationCancelled per activation that stood on a wait.

	scopeId		the scope, by id - the log is an outside-facing representation
	ownerName	the name of the node that opened it, or 'root' for an instance's own
"
Class {
	#name : 'FBScopeCancelled',
	#superclass : 'FBFlowInstanceEvent',
	#instVars : [
		'scopeId',
		'ownerName'
	],
	#category : 'FluxBase-Core-Event',
	#package : 'FluxBase-Core',
	#tag : 'Event'
}

{ #category : 'printing' }
FBScopeCancelled >> message [
	^ 'scope cancelled: ', ownerName asString
]

{ #category : 'accessing' }
FBScopeCancelled >> ownerName [
	^ ownerName
]

{ #category : 'printing' }
FBScopeCancelled >> printOn: aStream [ 
	super printOn: aStream.
	aStream << 'scope cancelled ' << ownerName asString
]

{ #category : 'accessing' }
FBScopeCancelled >> scope: aScope [
	scopeId := aScope id.
	ownerName := aScope ownerNode ifNil: [ 'root' ] ifNotNil: [ :node | node name ]
]

{ #category : 'accessing' }
FBScopeCancelled >> scopeId [
	^ scopeId
]

{ #category : 'accessing' }
FBScopeCancelled >> type [
	^ #scopeCancelled
]
