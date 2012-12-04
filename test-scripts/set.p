program setstuff(input, output);

(*** Demonstrate the set datatype. ***)

const
    one = 1;
    two = 2;
    three = 3;
    a = 'a';
    b = 'b';
    c = 'c';

type
   Digit = set of 0..9;
   cellPtr = ^cell;
   cell = record
       id: integer;
       info: char; 
       next: cellPtr
   end;

var
   odds, evens, stuff, morestuff: Digit;

function Square(input : integer) : integer;
begin
    Square := input * input;
end;

begin
   odds := [1, 3, 5, 7, 9];
   evens := [0, 2, 4, 6, 8];
   stuff := [];                (* empty set *)
   morestuff := odds + [2];    (* union of 2 sets *)

   if 3 in morestuff then
      writeln("3 in the set")
   else
      writeln("3 not in the set");

   if 4 in morestuff then
      writeln("4 in the set")
   else
      writeln("4 not in the set");
end.
