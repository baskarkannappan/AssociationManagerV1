window.razorpayInterop = {
    openCheckout: function (options, dotNetHelper) {
        options.handler = function (response) {
            dotNetHelper.invokeMethodAsync('HandlePaymentSuccess', response);
        };
        options.modal = {
            on_dismiss: function () {
                dotNetHelper.invokeMethodAsync('OnPaymentDismiss');
            }
        };
        var rzp = new Razorpay(options);
        rzp.open();
    }
};
