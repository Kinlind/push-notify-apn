{-# LANGUAGE OverloadedStrings #-}

module Network.PushNotify.APNSpec (spec) where

import           Data.Aeson
import           Network.PushNotify.APN
import           Test.Hspec

spec :: Spec
spec = do
  describe "JsonApsMessage" $
    context "JSON encoder" $ do
      it "encodes an APNS message with a title and body" $
        toJSON (alertMessage "hello" "world") `shouldBe`
          object [
            "alert"    .= object [
              "title" .= String "hello",
              "body"  .= String "world"
            ]
          ]
      it "encodes an APNS message with a title and no body" $
        toJSON (bodyMessage "hello world") `shouldBe`
          object [
            "alert"    .= object [ "body"  .= String "hello world" ]
          ]

  describe "JsonAps" $
    context "JSON encoder" $ do
      it "encodes normally when there are no supplemental fields" $
        toJSON (newMessage (alertMessage "hello" "world")) `shouldBe` object [
          "aps"                .= alertMessage "hello" "world",
          "appspecificcontent" .= Null
        ]

      it "encodes supplemental fields" $ do
        let msg = newMessage (alertMessage "hello" "world")
                  & addSupplementalField "foo" ("bar" :: String)
                  & addSupplementalField "aaa" ("qux" :: String)

        toJSON msg `shouldBe` object [
            "aaa"                .= String "qux",
            "aps"                .= alertMessage "hello" "world",
            "appspecificcontent" .= Null,
            "foo"                .= String "bar"
          ]

  describe "ApnFatalError" $
    context "JSON decoder" $ do
      it "decodes the error correctly" $
        eitherDecode "\"BadCollapseId\"" `shouldBe` Right ApnFatalErrorBadCollapseId

      it "dumps unknown error types into a wildcard result" $
        eitherDecode "\"BadcollapseId\"" `shouldBe` Right (ApnFatalErrorOther "BadcollapseId")

      it "errors on invalid JSON" $
        eitherDecode "\"crap" `shouldBe` (Left "Error in $: Failed reading: string without end" :: Either String ApnFatalError)

  describe "ApnTemporaryError" $
    context "JSON decoder" $
      it "decodes the error correctly" $
        eitherDecode "\"TooManyProviderTokenUpdates\"" `shouldBe` Right ApnTemporaryErrorTooManyProviderTokenUpdates
  where
    (&) = flip ($)
