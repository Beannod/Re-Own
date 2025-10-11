class Payments {
    static init() {
        Payments.bindOwnerActions();
        Payments.loadPayments();
        Payments.loadRenterPayments();
    }

    static bindOwnerActions() {
        document.getElementById('action-record-payment')?.addEventListener('click', async () => {
            try {
                const props = await API.getProperties().catch(() => []);
                const options = (props || []).map(p => `<option value="${p.id}">${p.title}</option>`).join('');

                const { value: formValues } = await Swal.fire({
                    title: 'Record Payment',
                    html: `
                        <div class="text-start">
                            <div class="mb-2">
                                <label class="form-label">Property</label>
                                <select id="swal-property" class="form-select">${options}</select>
                            </div>
                            <div class="mb-2">
                                <label class="form-label">Tenant ID</label>
                                <input id="swal-tenant" type="number" class="form-control" placeholder="Enter tenant user ID" />
                            </div>
                            <div class="mb-2">
                                <label class="form-label">Amount</label>
                                <input id="swal-amount" type="number" step="0.01" class="form-control" />
                            </div>
                            <div class="mb-2">
                                <label class="form-label">Type</label>
                                <select id="swal-type" class="form-select">
                                    <option value="rent">rent</option>
                                    <option value="deposit">deposit</option>
                                    <option value="utility">utility</option>
                                </select>
                            </div>
                            <div class="mb-2">
                                <label class="form-label">Method</label>
                                <select id="swal-method" class="form-select">
                                    <option value="card">card</option>
                                    <option value="bank_transfer">bank_transfer</option>
                                    <option value="cash">cash</option>
                                </select>
                            </div>
                            <div class="mb-2">
                                <label class="form-label">Status</label>
                                <select id="swal-status" class="form-select">
                                    <option value="completed">completed</option>
                                    <option value="pending">pending</option>
                                </select>
                            </div>
                            <div class="mb-2">
                                <label class="form-label">Payment Date</label>
                                <input id="swal-date" type="date" class="form-control" />
                            </div>
                        </div>
                    `,
                    focusConfirm: false,
                    showCancelButton: true,
                    preConfirm: () => {
                        const property_id = parseInt(document.getElementById('swal-property').value);
                        const tenant_id = parseInt(document.getElementById('swal-tenant').value);
                        const amount = parseFloat(document.getElementById('swal-amount').value);
                        const payment_type = document.getElementById('swal-type').value;
                        const payment_method = document.getElementById('swal-method').value;
                        const payment_status = document.getElementById('swal-status').value;
                        const dateStr = document.getElementById('swal-date').value;
                        if (!property_id || !tenant_id || isNaN(amount) || !dateStr) {
                            Swal.showValidationMessage('Please fill in all required fields');
                            return false;
                        }
                        const payment_date = new Date(dateStr).toISOString();
                        return { property_id, tenant_id, amount, payment_type, payment_method, payment_status, payment_date };
                    }
                });

                if (formValues) {
                    await API.createPayment(formValues);
                    Swal.fire('Saved', 'Payment recorded', 'success');
                    Payments.loadPayments();
                }
            } catch (e) {
                Swal.fire('Error', e.message || 'Failed to record payment', 'error');
            }
        });
    }

    static async loadPayments() {
        try {
            const payments = await API.getPayments();
            Payments.renderPaymentsTable(payments, 'owner-payments-table');
        } catch (error) {
            console.error('Failed to load payments', error);
        }
    }

    static async loadRenterPayments() {
        try {
            const token = Auth.getAuthToken();
            const payload = Util.decodeJWT(token) || {};
            if (!payload.user_id) return;
            const payments = await API.getPaymentsByTenant(payload.user_id);
            Payments.renderPaymentsTable(payments, 'renter-payments-table');
        } catch (error) {
            console.error('Failed to load renter payments', error);
        }
    }

    static renderPaymentsTable(payments, tableId) {
        const tbody = document.querySelector(`#${tableId} tbody`);
        if (!tbody) return;
        tbody.innerHTML = '';
        payments.forEach(p => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${p.property_title || p.property_id}</td>
                <td>${Util.formatCurrency(p.amount)}</td>
                <td>${p.payment_type}</td>
                <td>${p.payment_status}</td>
                <td>${new Date(p.payment_date).toLocaleDateString()}</td>
            `;
            tbody.appendChild(tr);
        });
    }

    static async updatePaymentStatus(id, status) {
        try {
            await API.updatePayment(id, { payment_status: status });
            Swal.fire('Success', 'Payment status updated!', 'success');
            Payments.loadPayments();
        } catch (err) {
            Swal.fire('Error', err.message, 'error');
        }
    }
}
