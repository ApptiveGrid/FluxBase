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
takes the #success transition, or the untagged ones; an FBRemoteFlowOutcome - a timeout
or a failure the other side reported - takes the transition it names, #timedOut or
#error, and stops me in error when that one is not modelled, the way a sub flow call
errors without an #error transition. A second impulse under the same address is silent,
that is the registry's promise, and so is a callback that arrives after the timeout or a
timeout that fires after the callback: whichever comes first consumes the address.

What goes out as the remote flow's input is #inputValueFor:, my activation's argument
unless a subclass assembles it from its own configuration.

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

{ #category : 'accessing' }
FBRemoteFlowTask >> inputValueFor: anActivation [
	"what the remote flow gets as its input when I run for anActivation: my argument, the
	value that reached me. A subclass that lets a modeller map fields onto the remote
	flow's schema assembles the input from those instead - the hook FBRemoteFlowBehavior
	reads, so that the behavior stays the same on both sides of that difference"
	^ anActivation argument
]

{ #category : 'testing' }
FBRemoteFlowTask >> isExternallyResumable [
	"my waker is the callback from the other side - outside the image by definition"
	^ true
]

{ #category : 'testing' }
FBRemoteFlowTask >> parksOnEntry [
	"I always park: my result comes from outside (FBRemoteFlowBehavior)"
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
	(aValue isKindOf: FBRemoteFlowOutcome)
		ifTrue: [ self didNotSucceed: aValue in: activation ]
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
FBRemoteFlowTask >> didNotSucceed: anOutcome in: anActivation [
	"a timeout or a reported failure: the transition the outcome names, or - none modelled
	- the activation stops in error, recorded the way FBFlowInstance>>activateProtected:
	would have recorded it. Not signalled as an error: this runs inside an impulse from
	outside (FBFlowInstance>>signal:with:), not inside the activation's protected block,
	so a signal here would escape to the caller and record nothing on the activation - the
	same reason FBSubFlowExecutor>>failCallerWith: marks instead of signals"
	(outgoing detect: [ :each | each resultName = anOutcome resultName ] ifNone: [ nil ])
		ifNotNil: [ :transition | ^ anActivation followTransition: transition ].
	anActivation errored.
	anActivation flowInstance addEvent: (FBNodeActivationErrored new
		activation: anActivation;
		activationError: anOutcome description, ' and no #', anOutcome resultName, ' transition is modelled')
]
