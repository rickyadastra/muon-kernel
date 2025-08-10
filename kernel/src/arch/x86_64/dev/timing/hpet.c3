module dev::timing::hpet;

import dev::acpi;
import muon::logging;

HPETTable hpetTable @local;

fn void? init() {
    hpetTable = *(HPETTable*)acpi::get_acpi_table(SIGNATURE)!;
    
    logging::printn("comparatorCount: %d", hpetTable.comparatorCount);
}
