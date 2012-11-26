program setstuff(input, output);

(*** Demonstrate the set datatype. ***)

const
   three = 3;
   four = 4;

type
   Digit = set of 0..9;
   int3d = array[1..3, 4..6, 7..9] of integer;

var
   odds, evens, stuff, morestuff: Digit;
   squareresult: integer;

Procedure Square(Index : Integer; Var Result : Integer);
Begin
    Result := Index * Index;
End;

begin
   odds := [1, 3, 5, 7, 9];
   evens := [0, 2, 4, 6, 8];
   stuff := [];                (* empty set *)
   morestuff := odds + [2];    (* union of 2 sets *)

   if 3 in morestuff then
   begin
      writeln("3 in the set");
      Square(3, squareresult);
      write(squareresult);
   end;
   if not (3 in morestuff) then
      writeln("3 not in the set");

   if 4 in morestuff then
      writeln("4 in the set");
   else
      writeln("4 not in the set");
end.
