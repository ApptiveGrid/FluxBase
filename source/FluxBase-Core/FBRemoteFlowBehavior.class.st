"
I run an FBRemoteFlowTask: park it, and send the call.

Parking first, then dispatching, because the call needs the address and the address is
minted by the parking - FBBaseActivation>>waitForNode:withToken: answers it. The other
side gets exactly what it needs to come back: the callback address, and nothing about
nodes, activations or executors, which have no meaning outside this image.

A port that fails to dispatch lets its error through: the activation is then recorded as
errored by FBFlowInstance>>activateProtected: and the instance stops - with the wait
still registered, which is harmless, since a stopped instance reports nothing open.
Retrying or failing softly is the port's business, not mine.
"
Class {
	#name : 'FBRemoteFlowBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBRemoteFlowBehavior >> execute [
	| address port call |
	address := activation waitForNode: self node withToken: activation token.
	port := self node dispatchPort.
	call := FBRemoteFlowCall new
		correlationId: address correlationId;
		callbackAddress: (FBCallbackAddress locator: port locator correlationId: address correlationId);
		targetFlowName: self node targetFlowName;
		inputValue: self argument;
		dispatchedAt: DateAndTime now;
		yourself.
	port dispatch: call
]
