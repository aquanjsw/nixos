import os
import subalter.views

from django.urls import path

urlpatterns = [
    path(os.environ["SUBSCRIPTION_NAME"], subalter.views.config),
]
