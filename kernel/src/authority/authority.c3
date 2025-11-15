module muon::authority;

import muon;

fn KernelObject? revoke(ObjectTable table, Handle handle) {
    logging::printn("Revoking handle %x", handle);
    return table.remove(handle);
}

fn Handle? delegate(ObjectTable srcTable, Handle srcHandle, ObjectTable destTable, ObjectRights rights) {
    logging::printn("Delegating handle %x", srcHandle);
    
    ObjectSlot* slot = srcTable.get(srcHandle);
    return destTable.insert(slot.object, rights);
}

fn void transfer(ObjectTable srcTable, Handle srcHandle, ObjectTable destTable) {

}
