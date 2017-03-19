import std.stdio, std.typecons;
import system: Entity, System, Property;

void main()
{
    System system = new System;
    const Entity en = system.add();
    const Entity en2 = system.add();
    const Entity en3 = system.add();
    auto prop = scoped!(Property!int)(system);
    prop.set(en, 1);
    prop.set(en2, 2);
    prop.set(en3, 3);

    writeln(system);
    writeln(cast(Property!int)(prop));

    auto prop2 = scoped!(Property!double)(system);
    prop2.set(en, 4.2);

    writeln(system);
    writeln(cast(Property!int)(prop));
    writeln(cast(Property!double)(prop2));

    system.kill(en2);

    writeln(system);
    writeln(cast(Property!int)(prop));
    writeln(cast(Property!double)(prop2));

    
}
