"
I call a flow that runs somewhere else - another process, another machine - and wait
for its result. The local counterpart is FBSubFlowNode, which runs its child inside the
caller's executor stack; my child is an instance of its own that I cannot see, so the
only thing that connects us is an address.

How it goes (FBRemoteFlowBehavior): when I run, I park myself the way a condition wait
does - my activation stands, my token is #waiting - and that parking makes me reachable
from outside, since I answer #isExternallyResumable. The address the registry hands out
becomes the correlationId of an FBRemoteFlowCall, wrapped into an FBCallbackAddress
together with my dispatch port's locator, and the call goes to the port. What the port
does with it - HTTP, a queue, a test block - is not my business (FBRemoteDispatchPort).

The result comes back as an impulse from outside, FBFlowInstance>>signal:with: with the
correlationId the callback carries, and I go on through my result transitions: a value
takes the #success transition, or the untagged ones; an FBRemoteFlowTimedOut takes the
#timedOut transition, and stops me in error when none is modelled - the way a sub flow
call errors without an #error transition. A second impulse under the same address is
silent, that is the registry's promise, and so is a callback that arrives after the
timeout or a timeout that fires after the callback: whichever comes first consumes the
address.

	targetFlowName	what the other side is to run - meaning is the port's
	maxWait		how long to wait for the result before a timeout, or nil for ever;
			the schedule that fires it is the environment's, not mine (see the
			deadline decision of 2026-09-01: the deadline lives at the schedule)
	dispatchPort	where a call goes, and where the locator of my callback address
			comes from

Abstract in the sense of the exposed node set only: without a transport there is nothing
a user could pick, so ApptiveBase's subclass, which brings the port, is the concrete
node type. Tests instantiate me directly with an FBPluggableDispatchPort.
"
Class {
	#name : 'FBRemoteFlowTask',
	#superclass : 'FBTask',
	#instVars : [
		'targetFlowName',
		'maxWait',
		'dispatchPort'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'testing' }
FBRemoteFlowTask class >> isAbstract [
	"see the class comment: out of the exposed node set until a subclass brings a
	transport; instantiable all the same"
	^ true
]

{ #category : 'accessing' }
FBRemoteFlowTask class >> typeName [
	^ #remoteFlow
]

{ #category : 'accessing' }
FBRemoteFlowTask >> defaultBehaviorClass [
	^ FBRemoteFlowBehavior
]

{ #category : 'accessing' }
FBRemoteFlowTask >> dispatchPort [
	^ dispatchPort
]

{ #category : 'accessing' }
FBRemoteFlowTask >> dispatchPort: aDispatchPort [
	dispatchPort := aDispatchPort
]

{ #category : 'testing' }
FBRemoteFlowTask >> isExternallyResumable [
	"my waker is the callback from the other side - outside the image by definition"
	^ true
]

{ #category : 'accessing' }
FBRemoteFlowTask >> maxWait [
	^ maxWait
]

{ #category : 'accessing' }
FBRemoteFlowTask >> maxWait: aDuration [
	maxWait := aDuration
]

{ #category : 'resuming' }
FBRemoteFlowTask >> resumeIn: anExecutor withToken: aToken value: aValue [
	"the result of the remote flow arrived - or a timeout in its place. My activation is
	still standing (FBNode>>resumeIn:withToken:value: explains why nothing is restored
	here); the impulse becomes its value, and which way I go on depends on what it is"
	| activation |
	activation := anExecutor activationOf: self.
	activation value: aValue.
	(aValue isKindOf: FBRemoteFlowTimedOut)
		ifTrue: [ self timedOut: activation ]
		ifFalse: [ self succeeded: activation ]
]

{ #category : 'resuming' }
FBRemoteFlowTask >> succeeded: anActivation [
	"a result: the #success transition where one is modelled, otherwise every untagged
	one - the plain arrow being the success path when only a #timedOut branch is tagged.
	Nothing wired at all means the implicit end, as for any node"
	| untagged |
	(outgoing detect: [ :each | each resultName = #success ] ifNone: [ nil ])
		ifNotNil: [ :transition | ^ anActivation followTransition: transition ].
	outgoing ifEmpty: [ ^ anActivation followAllOutgoing ].
	untagged := outgoing reject: [ :each | each resultName notNil ].
	untagged do: [ :each | anActivation followTransition: each ]
]

{ #category : 'accessing' }
FBRemoteFlowTask >> targetFlowName [
	^ targetFlowName
]

{ #category : 'accessing' }
FBRemoteFlowTask >> targetFlowName: aString [
	targetFlowName := aString
]

{ #category : 'resuming' }
FBRemoteFlowTask >> timedOut: anActivation [
	"no result within #maxWait: the #timedOut transition, or - none modelled - the
	activation stops in error, recorded the way FBFlowInstance>>activateProtected: would
	have recorded it. Not signalled as an error: this runs inside an impulse from outside
	(FBFlowInstance>>signal:with:), not inside the activation's protected block, so a
	signal here would escape to the caller and record nothing on the activation - the
	same reason FBSubFlowExecutor>>failCallerWith: marks instead of signals"
	(outgoing detect: [ :each | each resultName = #timedOut ] ifNone: [ nil ])
		ifNotNil: [ :transition | ^ anActivation followTransition: transition ].
	anActivation errored.
	anActivation flowInstance addEvent: (FBNodeActivationErrored new
		activation: anActivation;
		activationError: 'remote flow timed out and no #timedOut transition is modelled')
]
