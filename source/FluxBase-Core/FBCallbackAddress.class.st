"
I am the one string a remote flow gets and sends back: where to come back to, and which
wait is meant there. Two parts - a locator and a correlationId - in the generic form
decided on 2026-08-31 (form A):

	urn:fluxbase:instance:<locator>:<correlationId>

The locator is opaque to me: whatever the environment uses to find its way back to the
machine that waits - a host, a hook URL, a service name. It may contain colons, which is
why the correlationId is split off at the last one; a correlationId never contains a
colon (FBIdGenerator). The correlationId is the address inside that machine, resolved by
FBFlowInstance>>signal:with:. The locator is a hint for routing, not the truth: the wait
is found by its correlationId, and one registered elsewhere answers nothing
(FBFlowInstance>>waitingEntryFor:).

Making and parsing me is FluxBase's business, so that both sides agree without a
transport; resolving the locator to a network address is the environment's. An
environment may render the same two parts in a form of its own - a URL with the local
part embedded, the way ApptiveGrid's form links already are - as long as it parses them
back; #fromString: reads the generic form only.
"
Class {
	#name : 'FBCallbackAddress',
	#superclass : 'Object',
	#instVars : [
		'locator',
		'correlationId'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBCallbackAddress class >> fromString: aString [
	"the inverse of #asString; an FBError for anything that is not a callback address"
	| rest cut |
	(aString beginsWith: self prefix)
		ifFalse: [ FBError signal: 'not a callback address: ', aString printString ].
	rest := aString allButFirst: self prefix size.
	cut := rest lastIndexOf: $:.
	(cut < 2 or: [ cut = rest size ])
		ifTrue: [ FBError signal: 'callback address without locator or correlationId: ', aString printString ].
	^ self
		locator: (rest first: cut - 1)
		correlationId: (rest allButFirst: cut)
]

{ #category : 'instance creation' }
FBCallbackAddress class >> locator: aLocatorString correlationId: anIdString [
	^ self new
		setLocator: aLocatorString correlationId: anIdString;
		yourself
]

{ #category : 'private' }
FBCallbackAddress class >> prefix [
	^ 'urn:fluxbase:instance:'
]

{ #category : 'comparing' }
FBCallbackAddress >> = anObject [
	^ self class == anObject class
		and: [ locator = anObject locator and: [ correlationId = anObject correlationId ] ]
]

{ #category : 'converting' }
FBCallbackAddress >> asString [
	^ String streamContents: [ :stream |
		stream << self class prefix << locator << ':' << correlationId ]
]

{ #category : 'accessing' }
FBCallbackAddress >> correlationId [
	^ correlationId
]

{ #category : 'comparing' }
FBCallbackAddress >> hash [
	^ locator hash bitXor: correlationId hash
]

{ #category : 'accessing' }
FBCallbackAddress >> locator [
	^ locator
]

{ #category : 'printing' }
FBCallbackAddress >> printOn: aStream [
	aStream << self asString
]

{ #category : 'private' }
FBCallbackAddress >> setLocator: aLocatorString correlationId: anIdString [
	locator := aLocatorString.
	correlationId := anIdString
]
