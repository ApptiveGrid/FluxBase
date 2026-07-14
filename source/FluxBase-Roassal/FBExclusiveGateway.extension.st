Extension { #name : 'FBExclusiveGateway' }

{ #category : '*FluxBase-Roassal' }
FBExclusiveGateway >> asRoassalShape [
	| composite color |
	composite := RSComposite new.
	color := Color black alpha: 1.
	composite shapes: {
		RSLine new
			startPoint: -10@25;
			endPoint: 10@25;
			strokeColor: color;
			width: 2;
			yourself.
		RSLine new
			startPoint: 0@15;
			endPoint: 0@35;
			strokeColor: color;
			width: 2;
			yourself.
		(RSPolygon new
			points: (Array with: 0 @ 0 with: 25 @ 25 with: 0 @ 50 with: -25 @ 25);
			border: (RSBorder new width: 2; color: color);
			noPaint;
			yourself).
		 }.
	^ composite @ (RSLabeled new text: name; locationDo: [:l| l bottom ];fontSize: 6; lowColor: Color black )
		model: self;
		yourself
]
