module muon::authority;

import muon;

fn KernelObject? revoke(ObjectTable table, Handle handle) {
    logging::printn("Revoking handle %x", handle);
    return table.remove(handle);
}

fn void delegate(ObjectTable srcTable, Handle srcHandle, ObjectTable destTable, ObjectRights rights) {

}

fn void transfer(ObjectTable srcTable, Handle srcHandle, ObjectTable destTable) {

}
