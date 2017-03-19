import std.stdio;
import system: Entity, System, Property, makeProperty;
import std.typecons: scoped;

void main()
{
    System system = new System;
    const Entity en = system.add();
    const Entity en2 = system.add();
    const Entity en3 = system.add();
    auto prop = makeProperty!int(system);
    
    prop[en]  = 1;
    prop[en2] = 2;
    prop[en3] = 3;

    writeln(system);
    writeln(cast(Property!int)(prop));

    auto prop2 = makeProperty!double(system);
    prop2[en] = 4.2;

    writeln(system);
    writeln(prop.toString());
    writeln(prop2.toString());

    system.kill(en2);

    writeln(system);
    writeln(prop.toString());
    writeln(prop2.toString());
}
