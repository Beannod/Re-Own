class Utilities {
    static init() {
        Utilities.bindOwnerActions();
        Utilities.loadUtilities();
        Utilities.loadRenterUtilities();
    }

    static bindOwnerActions() {
        // Add Monthly Utility Readings
        document.getElementById('action-add-utility-reading')?.addEventListener('click', async () => {
            try {
                // Fetch properties to populate selector
                const props = await API.getProperties().catch(() => []);
                const options = (props || []).map(p => `<option value="${p.id}">${p.title}</option>`).join('');

                const { value: formValues } = await Swal.fire({
                    title: 'Add Utility Reading',
                    html: `
                        <div class="text-start">
                            <div class="mb-2">
                                <label class="form-label">Property</label>
                                <select id="swal-property" class="form-select">${options}</select>
                            </div>
                            <div class="mb-2">
                                <label class="form-label">Utility Type</label>
                                <select id="swal-utility-type" class="form-select">
                                    <option value="electricity">electricity</option>
                                    <option value="water">water</option>
                                    <option value="gas">gas</option>
                                </select>
                            </div>
                            <div class="mb-2">
                                <label class="form-label">Reading Date</label>
                                <input id="swal-reading-date" type="date" class="form-control" />
                            </div>
                            <div class="mb-2">
                                <label class="form-label">Reading Value</label>
                                <input id="swal-reading-value" type="number" step="0.01" class="form-control" />
                            </div>
                            <div class="mb-2">
                                <label class="form-label">Amount</label>
                                <input id="swal-amount" type="number" step="0.01" class="form-control" />
                            </div>
                            <div class="mb-2">
                                <label class="form-label">Status</label>
                                <select id="swal-status" class="form-select">
                                    <option value="pending">pending</option>
                                    <option value="paid">paid</option>
                                </select>
                            </div>
                        </div>
                    `,
                    focusConfirm: false,
                    showCancelButton: true,
                    preConfirm: () => {
                        const property_id = parseInt(document.getElementById('swal-property').value);
                        const utility_type = document.getElementById('swal-utility-type').value;
                        const reading_date = document.getElementById('swal-reading-date').value;
                        const reading_value = parseFloat(document.getElementById('swal-reading-value').value);
                        const amount = parseFloat(document.getElementById('swal-amount').value);
                        const status = document.getElementById('swal-status').value;
                        if (!property_id || !utility_type || !reading_date || isNaN(reading_value) || isNaN(amount)) {
                            Swal.showValidationMessage('Please fill in all required fields');
                            return false;
                        }
                        return { property_id, utility_type, reading_date, reading_value, amount, status };
                    }
                });

                if (formValues) {
                    await API.createUtility(formValues);
                    Swal.fire('Saved', 'Utility reading added', 'success');
                    Utilities.loadUtilities();
                }
            } catch (e) {
                Swal.fire('Error', e.message || 'Failed to add utility reading', 'error');
            }
        });
    }

    static async loadUtilities() {
        try {
            const utilities = await API.getUtilities();
            Utilities.renderUtilitiesTable(utilities, 'owner-utilities-table');
        } catch (error) {
            console.error('Failed to load utilities', error);
        }
    }

    static async loadRenterUtilities() {
        try {
            const token = Auth.getAuthToken();
            const payload = Util.decodeJWT(token) || {};
            if (!payload.user_id) return;
            const utilities = await API.getUtilitiesByTenant(payload.user_id);
            Utilities.renderUtilitiesTable(utilities, 'renter-utilities-table');
        } catch (error) {
            console.error('Failed to load renter utilities', error);
        }
    }

    static renderUtilitiesTable(utilities, tableId) {
        const tbody = document.querySelector(`#${tableId} tbody`);
        if (!tbody) return;
        tbody.innerHTML = '';
        utilities.forEach(u => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${u.property_title || u.property_id}</td>
                <td>${u.utility_type}</td>
                <td>${new Date(u.reading_date).toLocaleDateString()}</td>
                <td>${u.reading_value}</td>
                <td>${Util.formatCurrency(u.amount)}</td>
                <td>${u.status}</td>
            `;
            tbody.appendChild(tr);
        });
    }

    static async updateUtilityStatus(id, status) {
        try {
            await API.updateUtility(id, { status });
            Swal.fire('Success', 'Utility status updated!', 'success');
            Utilities.loadUtilities();
        } catch (err) {
            Swal.fire('Error', err.message, 'error');
        }
    }
}
