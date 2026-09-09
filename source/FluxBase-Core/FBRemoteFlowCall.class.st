"
I am what goes out when an FBRemoteFlowTask runs: everything the other side needs to
run its flow and to come back, and nothing else. A value object handed to the
FBRemoteDispatchPort; I am not kept by the engine - the wait itself is the state, kept
in the flow instance's waiting registry under my correlationId, and a second copy of it
here would be the kind of duplicate FluxBase keeps taking out.

	correlationId	the address of the wait, as the registry minted it
	callbackAddress	the FBCallbackAddress that embeds it together with the locator of
			the machine to come back to - the one string the other side sends back
	targetFlowName	what the other side is to run
	inputValue	the remote flow's input, FBRemoteFlowTask>>inputValueFor:
	flowInstance	the instance that waits - for the port, which may need it to render the
			callback address in a form of its own (an environment's local address
			names the instance next to the correlationId); a reference, never sent
	dispatchedAt	when the call went out - for whoever has to explain a wait later
"
Class {
	#name : 'FBRemoteFlowCall',
	#superclass : 'Object',
	#instVars : [
		'correlationId',
		'callbackAddress',
		'targetFlowName',
		'inputValue',
		'flowInstance',
		'dispatchedAt'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'accessing' }
FBRemoteFlowCall >> callbackAddress [
	^ callbackAddress
]

{ #category : 'accessing' }
FBRemoteFlowCall >> callbackAddress: aCallbackAddress [
	callbackAddress := aCallbackAddress
]

{ #category : 'accessing' }
FBRemoteFlowCall >> correlationId [
	^ correlationId
]

{ #category : 'accessing' }
FBRemoteFlowCall >> correlationId: aString [
	correlationId := aString
]

{ #category : 'accessing' }
FBRemoteFlowCall >> dispatchedAt [
	^ dispatchedAt
]

{ #category : 'accessing' }
FBRemoteFlowCall >> dispatchedAt: aDateAndTime [
	dispatchedAt := aDateAndTime
]

{ #category : 'accessing' }
FBRemoteFlowCall >> flowInstance [
	^ flowInstance
]

{ #category : 'accessing' }
FBRemoteFlowCall >> flowInstance: aFlowInstance [
	flowInstance := aFlowInstance
]

{ #category : 'accessing' }
FBRemoteFlowCall >> inputValue [
	^ inputValue
]

{ #category : 'accessing' }
FBRemoteFlowCall >> inputValue: anObject [
	inputValue := anObject
]

{ #category : 'printing' }
FBRemoteFlowCall >> printOn: aStream [
	super printOn: aStream.
	aStream << '(' << targetFlowName asString << ' -> ' << callbackAddress asString << ')'
]

{ #category : 'accessing' }
FBRemoteFlowCall >> targetFlowName [
	^ targetFlowName
]

{ #category : 'accessing' }
FBRemoteFlowCall >> targetFlowName: aString [
	targetFlowName := aString
]
