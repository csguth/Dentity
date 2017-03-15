import std.stdio;
import system: Entity, System;

void main()
{
    System a = new System;
    const Entity en = a.add();
    writeln("Entity ", en," is alive.");
}
