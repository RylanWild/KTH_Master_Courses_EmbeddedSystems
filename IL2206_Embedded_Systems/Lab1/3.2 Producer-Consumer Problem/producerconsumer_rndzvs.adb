with Ada.Text_IO;
use Ada.Text_IO;

with Ada.Real_Time;
use Ada.Real_Time;

with Ada.Numerics.Discrete_Random;

procedure ProducerConsumer_Rndzvs is
	
   N : constant Integer := 10; -- Number of produced and consumed tokens per task
	X : constant Integer := 3; -- Number of producers and consumers	
	
   -- Random Delays
   subtype Delay_Interval is Integer range 50..250;
   package Random_Delay is new Ada.Numerics.Discrete_Random (Delay_Interval);
   use Random_Delay;
   G : Generator;

   task type Buffer is
      entry Append(I : in Integer);
      entry Take(I : out Integer);
   end Buffer;

   task type Producer;

   task type Consumer;
   
   task body Buffer is
         Size: constant Integer := 4;--SIZE of the Buffer
         type Index is mod Size;
         type Item_Array is array(Index) of Integer;
         B : Item_Array;
         In_Ptr, Out_Ptr: Index := 0;
         Count : Integer range 0..Size := 0;
   begin
      loop
         select
            -- => Complete Code: Service Append
            when Count < Size =>
               accept Append(I: in Integer) do
                  B(In_Ptr) := I;
                  In_Ptr := In_Ptr + 1;
                  Count := Count + 1;
               end Append;
         or
				-- => Complete Code: Service Take
            when Count > 0 =>
               accept Take(I: out Integer) do
                  I := B(Out_Ptr);
                  Out_Ptr := Out_Ptr + 1;
                  Count := Count -1;
               end Take;
         or
				terminate; -- => Termination
         end select;
      end loop;
   end Buffer;
   
   Buf :Buffer;

   task body Producer is
      Next : Time;
   begin
      Next := Clock;
      for I in 1..N loop
         -- => Complete code: Write to X
         Buf.Append(I);
         -- Next 'Release' in 50..250ms
         Next := Next + Milliseconds(Random(G));
         delay until Next;
      end loop;
   end;

   task body Consumer is
      Next : Time;
      X : Integer;
   begin
      Next := Clock;
      for I in 1..N loop
         -- Complete Code: Read from X
         Buf.Take(X);   
         Put_Line(Integer'Image(X));
         Next := Next + Milliseconds(Random(G));
         delay until Next;
      end loop;
   end;
	
	P: array (Integer range 1..X) of Producer;
	C: array (Integer range 1..X) of Consumer;
	
begin -- main task
   null;
end ProducerConsumer_Rndzvs;


